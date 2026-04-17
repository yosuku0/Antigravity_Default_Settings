# AntigravityLab Runbook

## Prerequisites
Save the following 3 scripts to `F:\AntigravityLab\` before running:
- `initial-setup.ps1`
- `promote-runtime-assets.ps1`
- `validate-runtime.ps1`

## Initial Setup Procedure

### Step 1: Initial Build
```powershell
cd F:\AntigravityLab
.\initial-setup.ps1
```
Creates directories, clones upstream repos, extracts to skills_library,
generates manifest.md and runbook.md, and creates project template.
**Does NOT deploy to active_*.**

### Step 2: First Active Deployment
```powershell
.\promote-runtime-assets.ps1
```
Promotes assets from skills_library to active_rules / active_workflows / active_skills.
This is the only authorized deployment route to active_*.

### Step 3: Validation
```powershell
.\validate-runtime.ps1
```
**Must be run after promote.**
Validates all 24 items across Clone / Library / Active / Template categories.
All PASS = ready for use.

---

## Post-Upstream-Update Procedure

1. `git -C "F:\AntigravityLab\upstream\antigravity-awesome-skills" pull`
2. `git -C "F:\AntigravityLab\upstream\everything-claude-code" pull`
3. Manually re-extract desired assets to skills_library (delete existing then re-run initial-setup.ps1, or use Copy-Item directly)
4. `.\promote-runtime-assets.ps1 -Force` to re-promote to active
5. `.\validate-runtime.ps1` to re-validate

## Prohibited Actions
- Direct copy to active_* (must go through promote script)
- Editing files inside the upstream directory
- Overwriting template with initial-setup.ps1 re-run (existing files are protected)

## Documentation Update Policy (Guardrail)
文字化け（Mojibake）事故を防ぐため、以下の運用ルールを厳守してください。
- Markdown は PowerShell の直接的な文字列置換で触らない。
- ドキュメント更新時は「純粋な Native 環境からの UTF-8 明示書き込み」または「全文テンプレート」による再生成で行う。
- docs 変更後は必ず `Get-Content <file> -Encoding UTF8 | Select-Object -First 10` 等で先頭数行を確認すること。


## Machine Readable Status

- .\scripts\validate-runtime.ps1 -Json で他プロセス向けの終了ステータスとJSONサマリが取得可能です。

- 
runtime/manifest.md の実在は、その親が Antigravity のベースキャンプであることを示す root marker としてご活用ください。