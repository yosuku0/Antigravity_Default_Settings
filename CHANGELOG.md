# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-04-17
### Added
- Implemented machine-readable output mode (`-Json`) for `validate-runtime.ps1` with standard exit codes.
- Established "Documentation Update Policy" guardrail to prevent encoding corruption.

### Fixed
- Restored `README.md` encoding and fixed mojibake caused by shell string replacement.
- Fixed broken layout and typos in `runbook.md`.

## [1.0.0] - 2026-04-17
### Added
- Created foundational scripts (`initial-setup.ps1`, `promote-runtime-assets.ps1`, `validate-runtime.ps1`).
- Implemented environment agnostic pathing (repository relative paths) for setup scripts.
- Generated comprehensive `README.md`, `runbook.md`, and `manifest.md` documentation.
- Designed structured template generator (`projects/_template`) for bootstrapping AI-friendly context management.
- Hardened git clone logic by introducing proper `Start-Process` exit code validation to suppress PowerShell `NativeCommandError` misidentifications.
- Developed the validation script enforcing 24 check conditions across Clone, Library, Active, and Template zones.
- Configured robust `.gitignore` file to safeguard root repository structure from extracting and runtime state pollutions.
