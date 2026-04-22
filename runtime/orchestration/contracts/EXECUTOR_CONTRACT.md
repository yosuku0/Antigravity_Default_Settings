# Executor Contract

本文書は、オーケストレーション環境における Executor (CLI実行主体) の行為・責務・禁止事項・状態通知の契約 (Signaling Model)、および Lock の扱いを規定する。
(フィールド定義や生成タイミングの詳細については、`TASK_SCHEMA.md`, `RESULT_SCHEMA.md`, `NEXT_PROMPT_SCHEMA.md` を参照すること)

## 1. 権限と禁止事項 (What an Executor can/cannot do)
- **できること**:
  - `work/result.md` の生成と追記。
  - `work/next_prompt.md` の生成と追記・再生成。
  - 自己検証失敗により再実行へ戻る際 (`observing` → `executing`) の、stale な `work/next_prompt.md` の **自律的な破棄 (Discard)**。
  - `task.md` に定義された `capabilities_required` と Permission Mode の範囲内での操作。
  - 割り当てられた Job に対する Lock ファイルの生成と解放。
- **できないこと**:
  - **`work/task.md` の直接更新はいかなる状況でも禁止される**。`task.md` の Owner は Manager のみであり、Executor による直接の `status` 変更等は許されない。
  - Manager など他の Actor が Owner であるファイルを編集すること。

## 2. Artifact Ownership と Discard 例外
- **`next_prompt.md` の唯一の Writer**: `next_prompt.md` の Owner は Executor のみであり、内容の生成・追記・上書きは唯一 Executor のみが行う。
- **Manager / Human の Read-Only 権限**: Manager および Human は `next_prompt.md` の内容を読み取る権限のみを持つ。Manager はこれに追記・上書き・改変を行ってはならない。
- **Manager による Discard 例外**: Manager は、**stale handoff artifact の廃棄 (物理削除) のみ、例外的な Lifecycle Control として許可される**。
  - **許可される条件**: `observing` → `executing` (artifact 不足等・不足理由追記のため戻る時)、`observing` → `failed` (修復不能とManagerが判断した時)、`review` → `executing` (Human の差し戻し時) の遷移時。

## 3. Signaling Model (状態通知)
Executor は `task.md` を書き換えられない。そのため以下のシグナルを通じて Manager に状態を伝達し、Manager はそれらを受け取って `task.md` の `status` を確定更新する。

- **`stdout` / `stderr`**:
  - `assigned` → `executing` へ移行した際の開始シグナル。
  - 実行前失敗 (Pre-Execution Failure) の際のエラー出力報告 (result.md は用いない)。
- **`result.md`**:
  - `executing` ステート離脱時の「完遂」または「実行失敗 (理由記録)」のシグナル。
  - `observing` における自己検証失敗時 (修復不可判定含む) の「状況追記シグナル」。
- **`next_prompt.md`**:
  - `observing` → `review` へと進むための「自己検証成功 (準備完了)」のハンドオフ・シグナル。

## 4. Lock File Management (Lockの生成 / 解放責務)
- **配置**: `work/{job_id}.lock`
- **スコープ**: Job 単位 (1 Lock = 1 Job)。
- **生成の責務**: Executor が `assigned` から `executing` に移行する際に生成する。`observing` から `executing` への差し戻し時/自己検証失敗時に再実行する際も Executor が再生成する。
- **解放の責務**: Executor が `executing` ステートから離脱する際 (成功・失敗を問わず) に確定で削除する。
- **Stale Lock**: 自動回収は行わないため、デッドロックに陥った場合は Human が手動確認のうえ削除する。

## 5. Non-Goals
本契約では、以下を対象外 (Non-Goals) とする。
- Stale Lock の自動回収。
- YAML Schema の自動復元や `job_id` 等の Execution Safety (Strict) フィールドの自動補完。
- Manager による `next_prompt.md` の内容補完や追記。
