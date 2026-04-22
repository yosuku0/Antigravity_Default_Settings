# Manager Artifact Validator & Status Updater (Prototype v5 - Robust Loop)
# Note: Enforces strict schema consistency and performs frontmatter-safe task status updates.

param (
    [Parameter(Mandatory=$true)]
    [string]$WorkDir,
    [Parameter(Mandatory=$true)]
    [string]$TaskPath
)

$ErrorActionPreference = "Stop"

# --- Constants ---
$JobIdPattern = "^JOB-\d{8}-\d{3}$"
$ValidResults = @("PASS", "FAIL", "SKIPPED")
$ValidActions = @("continue", "wait_for_review", "fix_error")

$RequiredFields = @{
    "result.md" = @("job_id", "exit_code", "changed_files", "validation_result")
    "next_prompt.md" = @("job_id", "suggested_action")
}

# --- 1. Validation Layer ---

function Get-TaskContext {
    param([string]$Path)
    $Content = Get-Content $Path -Raw
    if ($Content -match "(?s)\A---\r?\n(.*?)\r?\n---") {
        $fm = $Matches[1]
        if ($fm -match "job_id\s*:\s*[`"']?([^`"'\s\r\n]+)[`"']?") {
            return @{ JobId = $Matches[1]; Frontmatter = $fm }
        }
    }
    return $null
}

function Validate-Artifact {
    param(
        [string]$File,
        [string[]]$Fields,
        [string]$RefJobId
    )
    
    if (-not (Test-Path $File)) {
        Write-Host "[Reject] Missing Artifact: $(Split-Path $File -Leaf)"
        return $false
    }

    $Content = Get-Content $File -Raw
    $Success = $true

    # Presence check
    foreach ($f in $Fields) {
        if ($Content -notmatch "$f\s*:") {
            Write-Host "[Reject] Violation in $(Split-Path $File -Leaf): Missing field '$f'"
            $Success = $false
        }
    }
    if (-not $Success) { return $false }

    # Strict Pattern & Consistency Audit (Cross-Artifact)
    if ($Content -match "job_id\s*:\s*[`"']?([^`"'\s\r\n]+)[`"']?") {
        $val = $Matches[1]
        if ($val -notmatch $JobIdPattern) {
            Write-Host "[Reject] Violation in $(Split-Path $File -Leaf): job_id '$val' pattern invalid."
            $Success = $false
        }
        if ($RefJobId -and $val -ne $RefJobId) {
            Write-Host "[Reject] Consistency Error in $(Split-Path $File -Leaf): job_id '$val' does not match task.md '$RefJobId'"
            $Success = $false
        }
    }

    # Enum Audit
    if ($File -match "result.md" -and $Content -match "validation_result\s*:\s*[`"']?([^`"'\s\r\n]+)[`"']?") {
        if ($ValidResults -notcontains $Matches[1]) {
            Write-Host "[Reject] Violation in result.md: Invalid validation_result '$($Matches[1])'"
            $Success = $false
        }
    }

    return $Success
}

# --- 2. Application Layer (Manager-Side) ---

function Apply-ManagerStatus {
    param(
        [string]$Path,
        [ValidateSet('assigned','review','failed')]
        [string]$NewStatus
    )
    
    Write-Host "[Manager] Applying status update: $NewStatus"
    $Raw = Get-Content $Path -Raw
    if ($Raw -notmatch "(?s)\A---\r?\n(.*?)\r?\n---") {
        throw "Frontmatter not found in $Path"
    }

    $Frontmatter = $Matches[1]
    $UpdatedFM = [regex]::Replace($Frontmatter, "(?m)^status\s*:\s*.+$", "status: $NewStatus")
    
    if ($UpdatedFM -eq $Frontmatter) {
        throw "status field not found in frontmatter: $Path"
    }

    $UpdatedContent = $Raw -replace "(?s)\A---\r?\n.*?\r?\n---", "---`n$UpdatedFM`n---"
    
    $Tmp = "$Path.tmp"
    [System.IO.File]::WriteAllText($Tmp, $UpdatedContent)
    Move-Item $Tmp $Path -Force
    Write-Host "[Success] Status automated: $NewStatus"
}

# --- 3. Main Logic ---

$Context = Get-TaskContext -Path $TaskPath
if ($null -eq $Context) {
    Write-Host "[Failure] Could not resolve task context from $TaskPath"
    exit 1
}

Write-Host "[Validator] Auditing artifacts against Job ID: $($Context.JobId)"
$AuditPassed = $true

# Validate result.md
if (-not (Validate-Artifact -File (Join-Path $WorkDir "result.md") -Fields $RequiredFields["result.md"] -RefJobId $Context.JobId)) {
    $AuditPassed = $false
}

# Validate next_prompt.md (Consistency check included if exists)
$NpPath = Join-Path $WorkDir "next_prompt.md"
if (Test-Path $NpPath) {
    if (-not (Validate-Artifact -File $NpPath -Fields $RequiredFields["next_prompt.md"] -RefJobId $Context.JobId)) {
        $AuditPassed = $false
    }
}

# Closing the loop
if ($AuditPassed) {
    Write-Host "[Signaling] All audits passed."
    Apply-ManagerStatus -Path $TaskPath -NewStatus "review"
    exit 0
} else {
    Write-Host "[Failure] Audit failed."
    Apply-ManagerStatus -Path $TaskPath -NewStatus "failed"
    exit 1
}
