# Walkthrough: Robust End-to-End Integrated Loop (Phase D)

Phase D の Repo 整合性を回復し、実装実体（v8 Wrapper / v5 Validator）とリポジトリ内の証跡を同期しました。

## 1. 永続的証跡の配置 (Repo-Local Evidence)

監査可能性を高めるため、一時ディレクトリではなくリポジトリ内の固定パスに検証結果を保存しました。

- **成功パス**: [docs/evidence/phase-d/success/](file:///j:/Dev/Antigravity_Default_Settings/docs/evidence/phase-d/success/)
  - `task.md` (status: review): バリデーターによる自動更新結果。
  - `validator.log`: 監査パスのログ。
- **失敗パス**: [docs/evidence/phase-d/failure/](file:///j:/Dev/Antigravity_Default_Settings/docs/evidence/phase-d/failure/)
  - `task.md` (status: failed): 監査失敗による自動更新結果。
  - `validator.log`: ID 不一致検知のログ。

## 2. CLI 実起動パスの実証 (v8 Wrapper)

Wrapper v8 にて、`npx @anthropic-ai/claude-code --version` を用いた実起動と出力キャプチャ（stdout/stderr）を実装しました。

- **実行コマンド**:
```powershell
.\runtime\orchestration\adapters\claude-code\claude_wrapper_prototype.ps1 -JobId "JOB-TEST" -TaskPath ".\work\task.md"
```
- **確認事項**:
  - `npx` 起動の成功。
  - 終了コードのキャプチャ。
  - `claude_stdout.log` / `claude_stderr.log` へのリダイレクト。

## 3. Strict Validator (suggested_action 監査)

Validator v5 にて、`next_prompt.md` の `suggested_action` が有効な enum 値（`continue`, `wait_for_review`, `fix_error`）であるかの監査を追加しました。

---

## 4. 安全性に関する明示
- **既存フック保護**: `ANTIGRAVITY_MANAGED_HOOK` マーカーがない既存フックを検知した場合、Fail-closed で停止することを [validator.log](file:///j:/Dev/Antigravity_Default_Settings/docs/evidence/phase-d/failure/validator.log) 等で実証。
- `ReadOnly` 保護は引き続き「暫定（Provisional）」レベルです。
