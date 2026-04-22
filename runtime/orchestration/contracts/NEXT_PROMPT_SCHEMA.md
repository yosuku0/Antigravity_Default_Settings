# Next Prompt Schema Contract

本文書は、オーケストレーション内で Executor を Owner とする `work/next_prompt.md` のスキーマ定義、生成タイミング、および例外的な破棄ルールを規定する。

## 1. Ownership & Immutable Principle
- `work/next_prompt.md` の **Owner (Writer) は Executor のみ** である。
- Manager および Human は read-only の読み取り権限のみを持つ。
- **Discard Exception**: Manager は、内容の追記・上書き・改変を禁じられているが、stale handoff artifact による Review 誤判定を防ぐ目的で、特定の遷移時において **物理削除 (discard) のみ** を例外的に許可される。

## 2. 生成条件と扱い

`next_prompt.md` は、Executor が自己検証を完了し、Review に進む準備ができた際に生成される **ハンドオフ (Handoff) アーティファクト** である。

- **生成時 (`observing` → `review` 移行前)**: Executor が `expected_artifacts` などの自己検証を終え、Human にレビューを依頼する準備ができた際に生成する。
- **生成しない条件 (Pre-Execution & Post-Execution Failure)**: 
  - `executing` 以前の失敗、または `executing` → `failed` への直接移行時には生成しない。
- **破棄時 (Executor および Manager による Discard)**:
  - **Executor Discard**: Executor 自身が自己検証失敗により self-correction ループ (`observing` → `executing`) へ戻る際、Executor は自身の責任で既存の stale な `next_prompt.md` を即時破棄する。
  - **Manager Discard**: Manager が `observing` ステートで artifact 不足などを検知し `status=executing` または `status=failed` へ遷移させる際、既存の `next_prompt.md` は即時破棄される。
  - **Manager Discard**: Human が Review 差し戻しを指示し、Manager が `status=executing` へ遷移させる際、既存の `next_prompt.md` は即時破棄される。

## 3. Field Classification Principle

| 分類 | Missing / Invalid 時の挙動 | 該当フィールド |
| :--- | :--- | :--- |
| **Auditability** | **Reject** (`status=failed`) | `job_id` |
| **Convenience** | **安全側 Default へフォールバック** (Warning) | `suggested_action` (→`wait_for_review`) |

※Executor 自身が生成するファイルであるため、Auditability フィールドの欠落は Executor 側の契約違反であり、Manager が読み取った際に Reject (`status=failed`) として処理する。

## 4. Schema Definition

| Field Name | Req | Type | Valid Values | Default / Fallback | Generated Timing | Missing / Invalid Handling |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `job_id` | Yes | string | Task の `job_id` と一致 | -- | `observing` での準備完了時 | Reject. `status=failed` |
| `suggested_action`| Yes | string | `continue`, `wait_for_review`, `fix_error` | `wait_for_review` | `observing` での準備完了時 | Missing も Invalid も `wait_for_review` へ強制 Fallback (Warning). |
