# Claude Code Experimental Wrapper (Prototype v7)
# Note: This is a design-to-code implementation of Phase C/D contracts.

param (
    [Parameter(Mandatory=$true)]
    [string]$JobId,
    [Parameter(Mandatory=$true)]
    [string]$TaskPath
)

$ErrorActionPreference = "Stop"

# --- 1. Environment & Path Config ---
$WorkDir = Split-Path $TaskPath -Parent
$LockFile = Join-Path $WorkDir "$JobId.lock"
$ProtectedPaths = @(
    $TaskPath,
    (Join-Path (Get-Location) "runtime/orchestration")
)
$NextPromptFile = Join-Path $WorkDir "next_prompt.md"
$HookMarker = "ANTIGRAVITY_MANAGED_HOOK"

# --- 2. Lock Creation (Fail-closed) ---
if (Test-Path $LockFile) {
    Write-Host "[Failure] Lock Conflict: $JobId is already locked."
    exit 1
}
New-Item -Path $LockFile -ItemType File | Out-Null
Write-Host "[Status] Lock acquired: $LockFile"

try {
    # --- 3. Enforcement: Multi-Layer Protection ---
    function Set-ReadOnly {
        param([string]$Path, [bool]$Value)
        if (Test-Path $Path) {
            $item = Get-Item $Path
            if ($Value) {
                $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::ReadOnly
            } else {
                $item.Attributes = $item.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
            }
        }
    }

    function Assert-EnforcementPolicy {
        param([string[]]$Paths)
        
        # A. Read-Only Protection (Provisional - Not Sandbox)
        Write-Host "[Enforcement] Applying Read-Only protection (Provisional)..."
        foreach ($p in $Paths) {
            Set-ReadOnly -Path $p -Value $true
        }
        
        # B. Git Push Block (Fail-closed hook)
        Write-Host "[Enforcement] Setting up Git Push block..."
        $GitDir = (git rev-parse --git-dir 2>$null)
        if ($GitDir) {
            $HookPath = Join-Path $GitDir "hooks/pre-push"
            if (Test-Path $HookPath) {
                $Content = Get-Content $HookPath -Raw
                if ($Content -notmatch $HookMarker) {
                    Write-Error "Pre-Execution Failure: Existing Git pre-push hook found. Fail-closed to avoid overwrite."
                }
            }
            $HookContent = "#!/bin/sh`n# $HookMarker`necho 'REJECTED: Git push is forbidden by Antigravity Contract.'`nexit 1"
            [System.IO.File]::WriteAllText($HookPath, $HookContent)
            Write-Host "  Push block installed at $HookPath"
        }
    }

    Assert-EnforcementPolicy -Paths $ProtectedPaths

    # --- 4. Self-Correction: Stale Artifact Discard ---
    if (Test-Path $NextPromptFile) {
        Write-Host "[Self-Correction] Discarding stale next_prompt.md..."
        Remove-Item $NextPromptFile -Force
    }

    # --- 5. Launch Claude Code (Simulated with lifecycle check) ---
    Write-Host "[Launch] Starting Claude Code Job: $JobId"
    # Simulated execution time for lifecycle audit
    Start-Sleep -Seconds 1 
    Write-Host "[Signal] Exit Code: 0"

} finally {
    # --- 6. Cleanup & Protection Release ---
    Write-Host "[Cleanup] Releasing protection..."
    foreach ($p in $ProtectedPaths) {
        Set-ReadOnly -Path $p -Value $false
    }
    
    # Remove push block only if it's ours
    $GitDir = (git rev-parse --git-dir 2>$null)
    if ($GitDir) {
        $HookPath = Join-Path $GitDir "hooks/pre-push"
        if (Test-Path $HookPath) {
            $Content = Get-Content $HookPath -Raw
            if ($Content -match $HookMarker) {
                Remove-Item $HookPath -Force
                Write-Host "  Push block removed."
            }
        }
    }

    # --- 7. Lock Release ---
    if (Test-Path $LockFile) {
        Remove-Item $LockFile -Force
        Write-Host "[Status] Lock released."
    }
}
