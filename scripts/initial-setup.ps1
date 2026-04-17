### initial-setup.ps1 — AntigravityLab Initial Setup v2.4.0 ###
$ErrorActionPreference = "Stop"
$baseRoot = Split-Path -Parent $PSScriptRoot

# ============================================================
# Helper: Write-Utf8NoBom
# ============================================================
function Write-Utf8NoBom($Path, $Content) {
    # Ensure directory exists
    $parent = Split-Path $Path -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

# ============================================================
# Step 1: Base Directories
# ============================================================
Write-Host "--- Step 1: Base Directories ---"
$dirs = @(
    "$baseRoot\upstream",
    "$baseRoot\runtime\skills_library\rules",
    "$baseRoot\runtime\skills_library\workflows",
    "$baseRoot\runtime\skills_library\skills",
    "$baseRoot\runtime\active_rules",
    "$baseRoot\runtime\active_workflows",
    "$baseRoot\runtime\active_skills",
    "$baseRoot\runtime\templates",
    "$baseRoot\projects\_template\.agent\rules",
    "$baseRoot\projects\_template\.agent\workflows",
    "$baseRoot\projects\_template\.agent\skills\local",
    "$baseRoot\projects\_template\.agent\decisions",
    "$baseRoot\projects\_template\.agent\tasks",
    "$baseRoot\archive"
)
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Write-Host "Created: $d"
    } else {
        Write-Host "Exists:  $d"
    }
}

# ============================================================
# Step 2: Upstream Clone & Pinning
# ============================================================
Write-Host "`n--- Step 2: Upstream Clone & Pinning ---"
$pinsPath = Join-Path $PSScriptRoot "upstream-pins.json"
if (-not (Test-Path $pinsPath)) {
    Write-Error "Missing upstream-pins.json in $($PSScriptRoot)"
    return
}
$pins = Get-Content $pinsPath | ConvertFrom-Json

foreach ($key in $pins.PSObject.Properties.Name) {
    $repoInfo = $pins.$key
    $repoDir = "$baseRoot\upstream\$key"
    $targetSha = $repoInfo.commit

    if (-not (Test-Path "$repoDir\.git")) {
        Write-Host "Cloning $key ($($repoInfo.url)) ..."
        $proc = Start-Process git -ArgumentList "clone", "`"$($repoInfo.url)`"", "`"$repoDir`"" -Wait -NoNewWindow -PassThru
        if ($proc.ExitCode -ne 0) { Write-Error "Clone failed: $key"; return }
    }

    Write-Host "Pinning $key to $targetSha ..."
    # Fetch to ensure we have the commit
    $null = Start-Process git -ArgumentList "-C", "`"$repoDir`"", "fetch", "origin" -Wait -NoNewWindow
    # Checkout specific SHA (detached HEAD)
    $proc = Start-Process git -ArgumentList "-C", "`"$repoDir`"", "checkout", "--detach", $targetSha -Wait -NoNewWindow -PassThru
    if ($proc.ExitCode -ne 0) {
        Write-Error "Failed to pin $key to $targetSha"
        return
    }
}

# ============================================================
# Step 3: Extract to Skills Library
# ============================================================
Write-Host "`n--- Step 3: Extract to Skills Library ---"
$libMap = @(
    @{ Type="File"; Name="RULES.md";
       Src="$baseRoot\upstream\everything-claude-code\RULES.md";
       Dest="$baseRoot\runtime\skills_library\rules\RULES.md" },
    @{ Type="Dir"; Name="writing-plans";
       Src="$baseRoot\upstream\antigravity-awesome-skills\skills\writing-plans";
       Dest="$baseRoot\runtime\skills_library\workflows\writing-plans" },
    @{ Type="Dir"; Name="verification-before-completion";
       Src="$baseRoot\upstream\antigravity-awesome-skills\skills\verification-before-completion";
       Dest="$baseRoot\runtime\skills_library\workflows\verification-before-completion" },
    @{ Type="Dir"; Name="context-manager";
       Src="$baseRoot\upstream\antigravity-awesome-skills\skills\context-manager";
       Dest="$baseRoot\runtime\skills_library\skills\context-manager" },
    @{ Type="Dir"; Name="security-review";
       Src="$baseRoot\upstream\everything-claude-code\skills\security-review";
       Dest="$baseRoot\runtime\skills_library\skills\security-review" }
)

foreach ($item in $libMap) {
    if (-not (Test-Path $item.Src)) { Write-Error "Upstream source missing: $($item.Src)"; return }
    if (Test-Path $item.Dest) {
        Write-Host "Skipped (Already in library): $($item.Name)"
    } else {
        if ($item.Type -eq "Dir") { Copy-Item $item.Src $item.Dest -Recurse } else { Copy-Item $item.Src $item.Dest }
        Write-Host "Extracted: $($item.Name)" -ForegroundColor Green
    }
}

# ============================================================
# Step 4: Generate runtime/manifest.md
# ============================================================
Write-Host "`n--- Step 4: Generate manifest.md ---"
$manifestPath = "$baseRoot\runtime\manifest.md"
if (-not (Test-Path $manifestPath)) {
$manifestContent = @"
# Antigravity Runtime Manifest & Loading Contract

## Priority Rules
AI context evaluation policy:
1. **[Highest] Project Local**: ``projects/[ProjectName]/.agent/`` directory
2. **[Medium] Runtime Active**: ``runtime/active_rules|active_workflows|active_skills/`` directories
3. **[Zero] Upstream**: ``upstream/`` is read-only reference — never load directly

## Runtime Constraints
- Never load files from ``upstream/`` as prompt context.
- When rules conflict, Project Local always wins.
- Changes to ``active_*`` must only be made via ``promote-runtime-assets.ps1``.

## Promotion Route
- upstream -> skills_library: handled by initial-setup.ps1
- skills_library -> active_*: handled by promote-runtime-assets.ps1 (manual execution only)
- Direct copy to active_* is prohibited

## Root Detection
This file marks the root of an Antigravity environment. Parent directory: $($baseRoot)
"@
    Write-Utf8NoBom $manifestPath $manifestContent
    Write-Host "Created: manifest.md" -ForegroundColor Green
} else {
    Write-Host "Skipped (Already exists): manifest.md"
}

# ============================================================
# Step 5: Generate runtime/runbook.md
# ============================================================
Write-Host "`n--- Step 5: Generate runbook.md ---"
$runbookPath = "$baseRoot\runtime\runbook.md"
if (-not (Test-Path $runbookPath)) {
$runbookContent = @"
# AntigravityLab Runbook

## Initial Setup Procedure

### Step 1: Initial Build
リポジトリルートで以下を実行します。

```powershell
.\scripts\initial-setup.ps1
```
Creates directories, clones upstream repos, extracts to skills_library,
generates manifest.md and runbook.md, and creates project template.
**Does NOT deploy to active_*.**

### Step 2: First Active Deployment

```powershell
.\scripts\promote-runtime-assets.ps1
```
Promotes assets from skills_library to active_rules / active_workflows / active_skills.
This is the only authorized deployment route to active_*.

### Step 3: Validation

```powershell
.\scripts\validate-runtime.ps1
```
**Must be run after promote.**
Validates all 24 items across Clone / Library / Active / Template categories.
All PASS = ready for use.

---

## Post-Upstream-Update Procedure
1. Edit ``scripts/upstream-pins.json`` with new SHAs.
2. Run Step 1 (initial-setup.ps1) again to checkout new versions.
3. ``.\scripts\promote-runtime-assets.ps1 -Force`` to re-promote to active.
4. ``.\scripts\validate-runtime.ps1`` to re-validate.

## Prohibited Actions
- Direct copy to active_* (must go through promote script)
- Editing files inside the upstream directory
- Overwriting template with initial-setup.ps1 re-run (existing files are protected)
"@
    Write-Utf8NoBom $runbookPath $runbookContent
    Write-Host "Created: runbook.md" -ForegroundColor Green
} else {
    Write-Host "Skipped (Already exists): runbook.md"
}

# ============================================================
# Step 6: Generate Project Templates
# ============================================================
Write-Host "`n--- Step 6: Generate Project Templates ---"
$tDir = "$baseRoot\projects\_template\.agent"

function Set-StarterFile ($Path, $Text) {
    if (-not (Test-Path $Path)) {
        Write-Utf8NoBom $Path $Text
        Write-Host "Created: $(Split-Path $Path -Leaf)"
    } else {
        Write-Host "Exists:  $(Split-Path $Path -Leaf)"
    }
}

Set-StarterFile "$tDir\README.md" @"
# Project Agent Configuration
Load files in this order when starting work:
1. project-context.md
2. current-focus.md
3. tasks/README.md
"@

Set-StarterFile "$tDir\project-context.md" @"
# Project Context
- Project Name: [Project Name]
- Goal: [Primary objective]
- Must NOT do: [Forbidden actions]
"@

Set-StarterFile "$tDir\current-focus.md" @"
# Current Focus
- Current Phase: [Phase]
- This week's top priority: [Priority]
- Areas to avoid right now: [Areas]
"@

Set-StarterFile "$tDir\source-of-truth.md" @"
# Source of Truth
- List authoritative URLs and documents here
"@

Set-StarterFile "$tDir\stack.md" @"
# Technology Stack
- Language: [TBD]
- Framework: [TBD]
"@

Set-StarterFile "$tDir\rules\default.md" @"
# Project Specific Rules
1. Do not make destructive changes without user confirmation.
2. Ask user permission before adding external libraries.
"@

Set-StarterFile "$tDir\workflows\default-dev-cycle.md" @"
# Default Development Cycle
1. Read context > focus > tasks in order
2. Draft implementation plan and confirm with user
3. Implement
4. Verification (must present one of the following):
   - lint / typecheck success log
   - test execution success log
   - manual operation confirmation log
5. Update tasks/README.md
"@

Set-StarterFile "$tDir\skills\local\README.md" @"
# Local Skills Directory
Place project-specific language or framework skills here.
"@

Set-StarterFile "$tDir\decisions\README.md" "# Architecture Decisions Record"

Set-StarterFile "$tDir\tasks\README.md" @"
# Task Board
- [ ] Initial setup
"@

# ============================================================
# Complete
# ============================================================
Write-Host "`n============================================================"
Write-Host "Initial setup complete."
Write-Host "Current Root: $baseRoot"
Write-Host "Next steps:"
Write-Host "  1. Run: .\scripts\promote-runtime-assets.ps1"
Write-Host "  2. Run: .\scripts\validate-runtime.ps1  (expect 24 PASS)"
Write-Host "============================================================"
