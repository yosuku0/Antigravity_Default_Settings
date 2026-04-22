---
job_id: "JOB-19700101-000" # Placeholder (Schema pattern: JOB-YYYYMMDD-NNN)
phase: design
status: assigned
assigned_executor: none
next_handoff_to: executor
approval_required:
  - push
capabilities_required:
  edit: false
  test: false
  commit: false
  push: false
  delete: false
  network: false
permission_mode: STRICT
source_root_mode: validate_required
expected_artifacts:
  - result.md
  - next_prompt.md
---

# Task Description

契約 `TASK_SCHEMA.md` に完全準拠した雛形。
Frontmatter は機械可読な制約の Source of Truth である。
Body は自然言語の指示を記述する。
