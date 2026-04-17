# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3] - 2026-04-17
### Added
- **Upstream Pinning**: Introduced `scripts/upstream-pins.json` to lock dependencies to specific commit SHAs.
- **Strict Validation**: Added `-PathType Leaf` enforcement and content header checks for `manifest.md` and `runbook.md`.
- **Encoding Safety**: Implemented `Write-Utf8NoBom` helper in all scripts to ensure consistent UTF-8 (No BOM) output.
- **Improved Portability**: Removed `I:\AntigravityArchive` hardcoded dependency and unified "any-path" execution model.

## [1.0.2] - 2026-04-17
### Added
- Established "Documentation Update Policy" guardrail in `runbook.md` to prevent future encoding corruption.

### Fixed
- Restored `README.md` encoding and fixed mojibake from previous shell replacement.
- Fixed broken layout and bullet formatting in `runbook.md`.
- Simplified `README.md` to reduce redundancy with `runbook.md`.

## [1.0.1] - 2026-04-17
### Added
- Implemented machine-readable output mode (`-Json`) for `validate-runtime.ps1` with standard PowerShell exit codes (0/1).
- Officially recognized `runtime/manifest.md` as the Antigravity Root Marker for environment detection.

## [1.0.0] - 2026-04-17
### Added
- Created foundational scripts (`initial-setup.ps1`, `promote-runtime-assets.ps1`, `validate-runtime.ps1`).
- Implemented environment agnostic pathing (repository relative paths) for setup scripts.
- Generated comprehensive `README.md`, `runbook.md`, and `manifest.md` documentation.
- Designed structured template generator (`projects/_template`) for bootstrapping AI-friendly context management.
- Hardened git clone logic by introducing proper `Start-Process` exit code validation to suppress PowerShell `NativeCommandError` misidentifications.
- Developed the validation script enforcing 24 check conditions across Clone, Library, Active, and Template zones.
- Configured robust `.gitignore` file to safeguard root repository structure from extracting and runtime state pollutions.
