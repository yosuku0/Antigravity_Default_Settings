# Task Schema Contract

本文書は、オーケストレーション内で Manager を Owner とする `work/task.md` のスキーマ定義、および Missing / Invalid 時のハンドリングルールを規定する。

## 1. Ownership & Immutable Principle
- `work/task.md` の **Owner は Manager のみ** である。
- Executor は内容を直接更新してはならず、Manager による `task.md` 更新プロセスは Signaling Model により駆動される。

## 2. Field Classification Principle
以下の分類原則に従い、安全側または Reject (拒絶) へ倒す。Manager による後補完 (値の埋め戻し) は監査証跡を汚染するため禁じられる。

| 分類 | Missing / Invalid 時の挙動 | 該当フィールド |
| :--- | :--- | :--- |
| **Execution Safety (Strict)** | **Reject** (`status=failed`)<br>※安全な代替値が無い、または代替付与が深刻な副作用を持つ。 | `job_id`, `status`, `assigned_executor`, `expected_artifacts`, `approval_required` |
| **Execution Safety (Safe Fallback)**| **最制限値を強制適用** (Warning)<br>※権限を縮小する方向のみ。 | `permission_mode`, `capabilities_required`, `source_root_mode` |
| **Convenience** | **安全側 Default を適用** (Warning) | `phase`, `next_handoff_to` |
| **Auditability** | 本スキーマでは該当なし (Result等に存在) | - |

## 3. Schema Definition

| Field Name | Req | Type | Enums / Valid Values | Default / Fallback | Missing / Invalid Handling |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `job_id` | Yes | string | `JOB-YYYYMMDD-NNN` | (None) | Reject. parse 可能なら `status=failed`, 不能なら stdout 報告のみ。 |
| `phase` | Yes | string | `design`, `execution`, `verification` | `design` | Fallback to `design` (Warning). Invalid は Reject (`status=failed`). |
| `status` | Yes | string | `inbox`, `assigned`, `executing`, `observing`, `review`, `done`, `failed` | `inbox` | Reject. `status` 自体が不明/Invalidなため stdout 報告のみ (書き戻し不可). |
| `assigned_executor`| Yes | string | `claude-code`, `gemini-cli`, `human`, `none` | `none` | Reject. `status=failed` |
| `permission_mode` | Yes | string | `STRICT`, `CONTROLLED`, `DANGEROUS` | `STRICT` | Force fallback to `STRICT` (Warning). |
| `capabilities_required`| Yes | dict | `edit`, `test`, `commit`, `push`, `delete`, `network` (bool)| all `false` | Force fallback to all `false` (Warning). 型異常は Reject (`failed`). |
| `approval_required` | Yes | list | `edit`, `test`, `commit`, `push`, `delete`, `network` | `['push']` | Reject. `status=failed` (空リストへのフォールバックは追加承認消失をもたらすため厳禁). |
| `source_root_mode` | Yes | string | `validate_required`, `skip_validate` | `validate_required` | Force fallback to `validate_required` (Warning). Invalid は Reject (`failed`). |
| `expected_artifacts`| Yes | list | e.g. `['result.md', 'next_prompt.md']` | (None) | Reject. `status=failed` |
| `next_handoff_to` | Yes | string | `executor`, `manager`, `human` | `executor` | Fallback to `executor` (Warning). Invalid は Reject (`failed`). |

## 4. `expected_artifacts` のセマンティクス

- **定義**: Post-Execution 成功時 (`observing` 状態) に Executor が生成すべき artifact 名のリスト。
- **評価タイミング**: Manager が `observing` → `review` への状態遷移を判断・実行するタイミングにおいて検証される。
- **Pre-Execution Failure時の扱い**: まだ Execution に入る前であるため、`expected_artifacts` の充足判定自体を行わない。
- **Post-Execution Failure時の扱い**: Executor による `status=failed` シグナルが出た場合、`expected_artifacts` の充足判定は放棄される。(`result.md` は失敗の証跡として生成が求められるが `next_prompt.md` は生成されなくてよい。それは `expected_artifacts` 不足での差し戻しではなく単段の「修復不能失敗」とみなされる)。
