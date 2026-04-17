### validate-runtime.ps1 窶・AntigravityLab Validation v2.3.4 ###
### Scope: Clone 2 + Library 5 + Active 7 + Template 10 = 24 items ###
$baseRoot = Split-Path -Parent $PSScriptRoot
$hasError = $false
$checkCount = 0

# For .git directories: only check existence (they are hidden dirs, not files)
function Test-DirValid ($Category, $Path) {
    $script:checkCount++
    if (Test-Path $Path -PathType Container) {
        Write-Host "[$Category] PASS (Dir exists): $(Split-Path $Path -Leaf)" -ForegroundColor Green
    } else {
        Write-Host "[$Category] FAIL (Missing dir): $Path" -ForegroundColor Red
        $script:hasError = $true
    }
}

# For regular files: check existence, size > 0, and read first line
function Test-FileValid ($Category, $Path) {
    $script:checkCount++
    if (-not (Test-Path $Path)) {
        Write-Host "[$Category] FAIL (Missing): $Path" -ForegroundColor Red
        $script:hasError = $true
        return
    }
    $info = Get-Item $Path -Force
    if ($info.PSIsContainer) {
        Write-Host "[$Category] PASS (Dir): $(Split-Path $Path -Leaf)" -ForegroundColor Green
        return
    }
    if ($info.Length -eq 0) {
        Write-Host "[$Category] FAIL (Empty 0 bytes): $Path" -ForegroundColor Red
        $script:hasError = $true
        return
    }
    $head = (Get-Content $Path -TotalCount 1)
    Write-Host "[$Category] PASS: $($info.Name) ($($info.Length) bytes | $head)" -ForegroundColor Green
}

# --- [1/4] Clone (2 items) ---
Write-Host "--- [1/4] Upstream Clone (2 items) ---"
Test-DirValid "Clone" "$baseRoot\upstream\antigravity-awesome-skills\.git"
Test-DirValid "Clone" "$baseRoot\upstream\everything-claude-code\.git"

# --- [2/4] Skills Library (5 items) ---
Write-Host "`n--- [2/4] Skills Library (5 items) ---"
Test-FileValid "Library" "$baseRoot\runtime\skills_library\rules\RULES.md"
Test-FileValid "Library" "$baseRoot\runtime\skills_library\workflows\writing-plans\SKILL.md"
Test-FileValid "Library" "$baseRoot\runtime\skills_library\workflows\verification-before-completion\SKILL.md"
Test-FileValid "Library" "$baseRoot\runtime\skills_library\skills\context-manager\SKILL.md"
Test-FileValid "Library" "$baseRoot\runtime\skills_library\skills\security-review\SKILL.md"

# --- [3/4] Active Runtime (7 items) ---
Write-Host "`n--- [3/4] Active Runtime (7 items) ---"
Test-FileValid "Active" "$baseRoot\runtime\manifest.md"
Test-FileValid "Active" "$baseRoot\runtime\runbook.md"
Test-FileValid "Active" "$baseRoot\runtime\active_rules\RULES.md"
Test-FileValid "Active" "$baseRoot\runtime\active_workflows\writing-plans\SKILL.md"
Test-FileValid "Active" "$baseRoot\runtime\active_workflows\verification-before-completion\SKILL.md"
Test-FileValid "Active" "$baseRoot\runtime\active_skills\context-manager\SKILL.md"
Test-FileValid "Active" "$baseRoot\runtime\active_skills\security-review\SKILL.md"

# --- [4/4] Project Template (10 items) ---
Write-Host "`n--- [4/4] Project Template (10 items) ---"
Test-FileValid "Template" "$baseRoot\projects\_template\.agent\README.md"
Test-FileValid "Template" "$baseRoot\projects\_template\.agent\project-context.md"
Test-FileValid "Template" "$baseRoot\projects\_template\.agent\current-focus.md"
Test-FileValid "Template" "$baseRoot\projects\_template\.agent\source-of-truth.md"
Test-FileValid "Template" "$baseRoot\projects\_template\.agent\stack.md"
Test-FileValid "Template" "$baseRoot\projects\_template\.agent\rules\default.md"
Test-FileValid "Template" "$baseRoot\projects\_template\.agent\workflows\default-dev-cycle.md"
Test-FileValid "Template" "$baseRoot\projects\_template\.agent\skills\local\README.md"
Test-FileValid "Template" "$baseRoot\projects\_template\.agent\decisions\README.md"
Test-FileValid "Template" "$baseRoot\projects\_template\.agent\tasks\README.md"

# --- Result ---
Write-Host ""
Write-Host "Checked: $checkCount / 24 items"
if ($hasError) {
    Write-Host "RESULT: FAILED 窶・fix items marked FAIL above." -ForegroundColor Red
} else {
    Write-Host "RESULT: All $checkCount checks PASSED. Ready for launch." -ForegroundColor Cyan
}

