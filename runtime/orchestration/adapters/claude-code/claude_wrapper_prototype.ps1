# Claude Code Execution Wrapper (Prototype v8 - Real Launch Path)
# Note: Manages job locks, physical protection, and CLI execution with output capture.

param (
    [Parameter(Mandatory=$true)]
    [string]$JobId,
    [Parameter(Mandatory=$true)]
    [string]$TaskPath,
    [string]$WorkDir = ".\work",
    [switch]$SimulationMode = $false
)

$ErrorActionPreference = "Stop"
$LockPath = Join-Path $WorkDir "$JobId.lock"
$ProtectedPaths = @($TaskPath, ".\runtime\orchestration")

# --- 1. Lifecycle Management: Lock ---
function Acquire-Lock {
    if (Test-Path $LockPath) {
        throw "Job Conflict: Lock file already exists at $LockPath"
    }
    New-Item -Path $LockPath -ItemType File | Out-Null
    Write-Host "[Status] Lock acquired: $LockPath"
}

function Release-Lock {
    if (Test-Path $LockPath) {
        Remove-Item $LockPath -Force
        Write-Host "[Status] Lock released."
    }
}

# --- 2. Discard: Clean state ---
function Clear-StaleArtifacts {
    $NextPrompt = Join-Path $WorkDir "next_prompt.md"
    if (Test-Path $NextPrompt) {
        Remove-Item $NextPrompt -Force
        Write-Host "[Status] Discarded stale next_prompt.md"
    }
}

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
    Write-Host "[Enforcement] Applying Read-Only protection (Provisional)..."
    foreach ($p in $Paths) { Set-ReadOnly -Path $p -Value $true }

    # B. Git Push Block (Fail-closed hook)
    $GitDir = (git rev-parse --git-dir 2>$null)
    if ($GitDir) {
        $HookPath = Join-Path $GitDir "hooks/pre-push"
        if (Test-Path $HookPath) {
            $Content = Get-Content $HookPath -Raw
            if ($Content -notmatch "ANTIGRAVITY_MANAGED_HOOK") {
                throw "Pre-Execution Failure: Existing Git pre-push hook found. Fail-closed to avoid overwrite."
            }
        }
        Write-Host "[Enforcement] Setting up Git Push block (Managed Hook)..."
        $HookContent = @"
#!/bin/sh
# ANTIGRAVITY_MANAGED_HOOK
echo 'REJECTED: Push is disabled during Antigravity orchestration.'
exit 1
"@
        [System.IO.File]::WriteAllText($HookPath, $HookContent)
    }
}

function Remove-EnforcementPolicy {
    param([string[]]$Paths)
    Write-Host "[Cleanup] Releasing protection..."
    foreach ($p in $Paths) { Set-ReadOnly -Path $p -Value $false }

    $GitDir = (git rev-parse --git-dir 2>$null)
    if ($GitDir) {
        $HookPath = Join-Path $GitDir "hooks/pre-push"
        if (Test-Path $HookPath) {
            $Content = Get-Content $HookPath -Raw
            if ($Content -match "ANTIGRAVITY_MANAGED_HOOK") {
                Remove-Item $HookPath -Force
                Write-Host "[Cleanup] Removed managed Git hook."
            }
        }
    }
}

# --- 4. Execution Layer: Real CLI Launch ---
function Invoke-ClaudeCLI {
    if ($SimulationMode) {
        Write-Host "[Execution] Simulation Mode: Skipping real NPX call."
        Start-Sleep -Seconds 2
        return 0
    }

    Write-Host "[Execution] Launching Claude Code via NPX..."
    try {
        # Note: In production, this would be: npx @anthropic-ai/claude-code --once ...
        # For prototype, we use --version to prove execution and capture
        $process = Start-Process -FilePath "npx.cmd" -ArgumentList "@anthropic-ai/claude-code --version" -NoNewWindow -PassThru -Wait -RedirectStandardOutput "claude_stdout.log" -RedirectStandardError "claude_stderr.log"
        $exitCode = $process.ExitCode
        Write-Host "[Execution] Completed with Exit Code: $exitCode"
        return $exitCode
    } catch {
        Write-Host "[Error] Failed to launch NPX: $($_.Exception.Message)"
        return 1
    }
}

# --- Main Logic ---
try {
    Acquire-Lock
    Clear-StaleArtifacts
    Assert-EnforcementPolicy -Paths $ProtectedPaths

    $ExitCode = Invoke-ClaudeCLI
    Write-Host "[Status] Execution Phase Finished (ExitCode: $ExitCode)"

} finally {
    Remove-EnforcementPolicy -Paths $ProtectedPaths
    Release-Lock
}
