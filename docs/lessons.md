# Lessons Learned: Phase D Implementation

## Orchestration Loop & Status Updates
- **Frontmatter Safety**: When updating status in `task.md`, regex replacement must be restricted to the frontmatter block (between `---`) to avoid accidental modification of status strings in the document body.
- **Cross-Artifact Consistency**: Job ID validation should encompass all expected artifacts (e.g., `result.md`, `next_prompt.md`) to ensure the entire execution cycle is anchored to the same task.

## Enforcement & Security
- **Fail-Closed Hooks**: When managing git hooks for protection, always check for existing hooks and refuse execution if a non-managed hook is present. Use unique markers (e.g., `ANTIGRAVITY_MANAGED_HOOK`) to distinguish and safely clean up managed hooks.
- **Bitwise Attribute Management**: When setting or removing file attributes (like `ReadOnly`), use bitwise operators (`bor`, `band`) to preserve other existing attributes (Hidden, System, etc.).
