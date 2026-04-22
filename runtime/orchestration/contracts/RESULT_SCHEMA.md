# Result Schema Contract

本文書は、オーケストレーション内で Executor を Owner とする `work/result.md` のスキーマ定義、および生成条件を規定する。

## 1. Ownership & Immutable Principle
- `work/result.md` の **Owner は Executor のみ** である。
- Manager および Human は内容の読み取りのみを許可される。

## 2. 生成条件と扱い

`result.md` は、**`executing` ステートに入ったジョブの実行結果を記録する (成功・失敗を問わない) ためのアーティファクト** である。

- **成功時 (Post-Execution Success)**:
  - `executing` → `observing` への移行時に生成される。
  - Executor が「自身に課せられた命令を完遂した」と判断した時に生成する。
- **失敗時 (Post-Execution Failure)**:
  - `executing` → `failed` への移行時にも生成される。
  - Capability 違反（実行不可な操作等）、Network/Commit 拒否、内部コマンドエラー等の理由を含め、失敗の証拠 (Denial Reason等) を記録して出力する。
- **生成しない条件 (Pre-Execution Failure)**:
  - `executing` ステートに入る前の失敗 (Schema 定義違反、Lock 競合、Validate 失敗等) では **生成してはならない**。これらの失敗は Manager により `status=failed` への更新と stdout/stderr のみで通知される。

## 3. Field Classification Principle

| 分類 | Missing / Invalid 時の挙動 | 該当フィールド |
| :--- | :--- | :--- |
| **Auditability** | **Reject** (`status=failed`) | `job_id`, `exit_code`, `changed_files` |
| **Convenience** | **安全側 Default へフォールバック** (Warning) | `validation_result` (→`SKIPPED`) |

※Executor 自身が生成するファイルであるため、`result.md` が Auditability フィールドの欠落を持って生成された場合は Executor 側の契約違反であり、Manager が読み取った際に `status=failed` として処理する。

## 4. Schema Definition

| Field Name | Req | Type | Valid Values | Default / Fallback | Generated Timing | Missing / Invalid Handling |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `job_id` | Yes | string | Task の `job_id` と一致 | -- | `executing` 離脱時 | Reject. `status=failed` |
| `exit_code` | Yes | int | `0-255` | -- | `executing` 離脱時 | Reject. `status=failed` |
| `changed_files` | Yes | list | Root からの相対パス配列 | -- | `executing` 離脱時 | Reject. `status=failed` |
| `validation_result`| Yes | string | `PASS`, `FAIL`, `SKIPPED` | `SKIPPED` | `executing` 離脱時 | Fallback to `SKIPPED` (Warning). Invalid は Reject (`failed`). |

**特記事項**:
- `validation_result` は Executor 内での自律的な Lint などの結果を記載し、Manager / Human が Review 時の参考にするための Convenience フィールドである。
