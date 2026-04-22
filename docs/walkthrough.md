# Walkthrough: End-to-End Integrated Loop (Phase D Re-Submission)

Phase D の実装実体（v7 Wrapper / v5 Validator）に基づき、クローズドループの動作を **Success / Failure の独立ディレクトリ** で実証しました。

## 1. Success Path 実証 (test_integration_success/)

Artifact がすべて正常な場合に、Manager が `task.md` の Frontmatter 内の status のみを更新することを実証しました。

- **実行コマンド**:
```powershell
pwsh -Command ".\runtime\orchestration\adapters\claude-code\manager_validator_prototype.ps1 -WorkDir '.\test_integration_success' -TaskPath '.\test_integration_success\task.md'"
```
- **出力ログ**:
```text
[Validator] Auditing artifacts against Job ID: JOB-20260422-001
[Signaling] All audits passed.
[Manager] Applying status update: review
[Success] Status automated: review
```
- **実ファイル証跡 (更新後)**: test_integration_success/task.md
```yaml
status: review
```

## 2. Failure Path 実証 (test_integration_failure/)

`next_prompt.md` の `job_id` が不一致（`BAD-JOB-ID`）な場合に、監査が失敗し status が `failed` になることを実証しました。

- **実行コマンド**:
```powershell
pwsh -Command ".\runtime\orchestration\adapters\claude-code\manager_validator_prototype.ps1 -WorkDir '.\test_integration_failure' -TaskPath '.\test_integration_failure\task.md'"
```
- **出力ログ**:
```text
[Validator] Auditing artifacts against Job ID: JOB-20260422-001
[Reject] Violation in next_prompt.md: job_id 'BAD-JOB-ID' pattern invalid.
[Reject] Consistency Error in next_prompt.md: job_id 'BAD-JOB-ID' does not match task.md 'JOB-20260422-001'
[Failure] Audit failed.
[Manager] Applying status update: failed
[Success] Status automated: failed
```
- **実ファイル証跡 (更新後)**: test_integration_failure/task.md
```yaml
status: failed
```

## 3. 物理的保護の証拠 (Fail-closed)

既存のフックがある場合に上書きを拒否して安全に停止するログを再提出します。

- **状況**: マーカーのない既存フックを配置してラッパーを起動。
- **結果ログ抜粋**:
```text
[Status] Lock acquired: ...
[Enforcement] Applying Read-Only protection (Provisional)...
[Enforcement] Setting up Git Push block...
Write-Error: ... Pre-Execution Failure: Existing Git pre-push hook found. Fail-closed to avoid overwrite.
```

---

## 4. 実装の安全性と区分
- **検証 (Validation)** と **適用 (Application)** を関数レベルで分離し、副作用のない構成にしました。
- `ReadOnly` 保護は引き続き「暫定（Provisional）」レベルであり、サンドボックスによる完全な物理隔離ではありません。
