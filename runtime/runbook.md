# AntigravityLab Runbook

## Initial Setup Procedure

### Step 1: Initial Build
``powershell
cd J:\Dev\Antigravity_Default_Settings
.\scripts\initial-setup.ps1
``
Creates directories, clones upstream repos, extracts to skills_library,
generates manifest.md and runbook.md, and creates project template.
**Does NOT deploy to active_*.**

### Step 2: First Active Deployment
``powershell
.\scripts\promote-runtime-assets.ps1
``
Promotes assets from skills_library to active_rules / active_workflows / active_skills.
This is the only authorized deployment route to active_*.

### Step 3: Validation
``powershell
.\scripts\validate-runtime.ps1
``
**Must be run after promote.**
Validates all 24 items across Clone / Library / Active / Template categories.
All PASS = ready for use.

---

## Post-Upstream-Update Procedure
1. Edit `scripts/upstream-pins.json` with new SHAs.
2. Run Step 1 (initial-setup.ps1) again to checkout new versions.
3. `.\scripts\promote-runtime-assets.ps1 -Force` to re-promote to active.
4. `.\scripts\validate-runtime.ps1` to re-validate.

## Prohibited Actions
- Direct copy to active_* (must go through promote script)
- Editing files inside the upstream directory
- Overwriting template with initial-setup.ps1 re-run (existing files are protected)