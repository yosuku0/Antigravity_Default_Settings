param (
    [switch]$Json
)

### validate-runtime.ps1 窶・AntigravityLab Validation v2.4.0 ###
### Scope: Clone 2 + Library 5 + Active 7 + Template 10 = 24 items ###
$baseRoot = Split-Path -Parent $PSScriptRoot
$hasError = $false
$checkCount = 0
$passedCount = 0
$failedItems = @()

# For .git directories: strictly check for directory existence
function Test-DirValid ($Category, $Path) {
    $script:checkCount++
    if (Test-Path $Path -PathType Container) {
        $script:passedCount++
        if (-not $Json) { Write-Host "[$Category] PASS (Dir exists): $(Split-Path $Path -Leaf)" -ForegroundColor Green }
    } else {
        $script:hasError = $true
        $script:failedItems += "[$Category] Missing or not a dir: $Path"
        if (-not $Json) { Write-Host "[$Category] FAIL (Missing/Not a dir): $Path" -ForegroundColor Red }
    }
}

# For regular files: check existence (Leaf only), size > 0, and optional header check
function Test-FileValid ($Category, $Path, $ExpectedHeader = "") {
    $script:checkCount++
    
    # Strict existence check (must be a file/Leaf)
    if (-not (Test-Path $Path -PathType Leaf)) {
        $script:hasError = $true
        $script:failedItems += "[$Category] Missing or not a file: $Path"
        if (-not $Json) { Write-Host "[$Category] FAIL (Missing/Not a file): $Path" -ForegroundColor Red }
        return
    }

    $info = Get-Item $Path -Force
    if ($info.Length -eq 0) {
        $script:hasError = $true
        $script:failedItems += "[$Category] Empty 0 bytes: $Path"
        if (-not $Json) { Write-Host "[$Category] FAIL (Empty): $Path" -ForegroundColor Red }
        return
    }

    # Optional content validation
    if ($ExpectedHeader) {
        $content = Get-Content $Path -TotalCount 5 | Out-String
        if ($content -notmatch [regex]::Escape($ExpectedHeader)) {
            $script:hasError = $true
            $script:failedItems += "[$Category] Content mismatch (Missing '$ExpectedHeader'): $Path"
            if (-not $Json) { Write-Host "[$Category] FAIL (Header mismatch): $Path" -ForegroundColor Red }
            return
        }
    }

    $script:passedCount++
    if (-not $Json) {
        $head = (Get-Content $Path -TotalCount 1)
        Write-Host "[$Category] PASS: $($info.Name) ($($info.Length) bytes | $head)" -ForegroundColor Green
    }
}

# --- [1/4] Clone (2 items) ---
if (-not $Json) { Write-Host "--- [1/4] Upstream Clone (2 items) ---" }
Test-DirValid "Clone" "$baseRoot\upstream\antigravity-awesome-skills\.git"
Test-DirValid "Clone" "$baseRoot\upstream\everything-claude-code\.git"

# --- [2/4] Skills Library (5 items) ---
if (-not $Json) { Write-Host "`n--- [2/4] Skills Library (5 items) ---" }
Test-FileValid "Library" "$baseRoot\runtime\skills_library\rules\RULES.md"
Test-FileValid "Library" "$baseRoot\runtime\skills_library\workflows\writing-plans\SKILL.md"
Test-FileValid "Library" "$baseRoot\runtime\skills_library\workflows\verification-before-completion\SKILL.md"
Test-FileValid "Library" "$baseRoot\runtime\skills_library\skills\context-manager\SKILL.md"
Test-FileValid "Library" "$baseRoot\runtime\skills_library\skills\security-review\SKILL.md"

# --- [3/4] Active Runtime (7 items) ---
if (-not $Json) { Write-Host "`n--- [3/4] Active Runtime (7 items) ---" }
Test-FileValid "Active" "$baseRoot\runtime\manifest.md" "# Antigravity Runtime Manifest"
Test-FileValid "Active" "$baseRoot\runtime\runbook.md" "# AntigravityLab Runbook"
Test-FileValid "Active" "$baseRoot\runtime\active_rules\RULES.md"
Test-FileValid "Active" "$baseRoot\runtime\active_workflows\writing-plans\SKILL.md"
Test-FileValid "Active" "$baseRoot\runtime\active_workflows\verification-before-completion\SKILL.md"
Test-FileValid "Active" "$baseRoot\runtime\active_skills\context-manager\SKILL.md"
Test-FileValid "Active" "$baseRoot\runtime\active_skills\security-review\SKILL.md"

# --- [4/4] Project Template (10 items) ---
if (-not $Json) { Write-Host "`n--- [4/4] Project Template (10 items) ---" }
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
if ($Json) {
    $resultObj = @{
        ok = -not $hasError
        checked = $checkCount
        passed = $passedCount
        failed = $failedItems
        summary = if ($script:hasError) { "Validation FAILED for $($script:failedItems.Count) items" } else { "All $script:checkCount checks PASSED" }
    }
    $resultObj | ConvertTo-Json -Depth 5 -Compress:($false)
    if ($hasError) { exit 1 } else { exit 0 }
} else {
    Write-Host ""
    Write-Host "Checked: $script:checkCount / 24 items"
    if ($script:hasError) {
        Write-Host "RESULT: FAILED — fix items marked FAIL above." -ForegroundColor Red
        exit 1
    } else {
        Write-Host "RESULT: All $script:checkCount checks PASSED. Ready for launch." -ForegroundColor Cyan
        exit 0
    }
}
