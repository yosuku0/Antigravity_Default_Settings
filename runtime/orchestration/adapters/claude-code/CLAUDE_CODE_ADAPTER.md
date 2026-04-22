# Claude Code Adapter Design

本文書は、`Claude Code` (CLI) を Executor として `Executor Contract` に適合させるための Adapter 設計仕様を定義する。
※本フェーズでは設計のみ行い、実装コードの記述は対象外 (Non-Goals) とする。

## 1. 3層分離と Artifact Ownership

Claude Code 環境は、設計の安定性を保つため 3 層分離モデルに従う。

- **Model Layer (Claude Code 本体)**: `task.md` を「Read-Only な要求仕様書」として扱い、`result.md` および `next_prompt.md` を直接出力する **唯一の Writer** である。
- **Adapter Wrapper Layer**: Lock 管理、プロセス起動、出力 capture、および fail-closed 制御を担う。Artifact の直接生成や書き換えは行わない。
- **Manager Layer**: `task.md` 更新、Artifact の Discard 操作を担当する。

## 2. Enforcement Layer (権限・安全設定のマッピング)

高リスク操作がプロンプト依存に留まることを防ぎ、fail-closed で安全を担保するため、`capabilities_required` と `approval_required` は以下のレイヤーで多層防御される。

| 操作 | 制御レイヤー (Enforcement Layer) | 制御方法 |
| :--- | :--- | :--- |
| `edit`, `test` | **Model Layer** (Prompt) | System Prompt (Do/Don't リスト) で許可/制限を指示 (※保護対象パスは除く)。<br>※ 破壊的な上書き・Truncate等による破壊は、単なる `edit` ではなく `delete` と等価に扱い Wrapper 等で fail-closed とする。 |
| `delete` | **Adapter Wrapper** + **Sandbox** + **Gate** | プロンプトのみに依存させず、ファイルシステム隔離 (Sandbox) や Wrapper フック、Human Review Gate により破壊的操作を fail-closed で物理的に防ぐ。 |
| `commit` | **Adapter Wrapper** (Fail-closed) | Launcher policy、VCS hook、または Wrapper Layer の設定によって fail-closed でブロックする。具体的な起動フラグ等は実装フェーズで確定する。 |
| `push` | **Adapter Wrapper** + **Manager** | 高リスク。プロンプト依存にせず、VCS hook 等による強制的ブロック。必ず Human / Manager の Review ゲートを経由させる。 |
| `network` | **Adapter Wrapper** (Fail-closed) | ネットワーク通信をブロックする Sandbox / 環境変数制御等で強制遮断。 |

## 3. Manager-Owned Files の実効的保護 (`task.md` への書き込み禁止)

契約文書や Manager 所有の Artifact が改変されないよう、以下の多層保護を敷く。
- **保護対象の全体化**: 保護対象は `contracts/**` のみならず、アダプターやラッパー設計を含む **`runtime/orchestration/**` 全体** に適用する (これらは静的参照資産であるため)。
- **Model Layer**: `task.md` および対象パス全体を Read-Only と扱うようプロンプトで指示する。
- **Adapter Wrapper Layer**:
  - `task.md` および `runtime/orchestration/**` は、Path Allowlist / Filesystem Isolation / Hook / Managed Settings などの仕組みを用いて、Wrapper・Sandbox レベルで **Write および破壊的 Overwrite を物理的に禁止 (fail-closed)** する。

## 4. Discard 主体の扱い (Self-correction)

- **Executor Discard (Self-correction)**: Claude Code が検証 (lint 等) に失敗し再実行を判断した際は、Claude Code 自身の操作により、既存の stale な `next_prompt.md` を **物理削除のみ** (上書きによる隠蔽不可) 行うようプロンプトで厳格に指示する。
- **Manager Discard**: 実行を終え、Manager 側で Artifact 不足や Human 差し戻しが発生した場合は、Manager が物理削除を行う。Claude Code はこれに関与しない。

## 5. Review 差し戻し後の再実行 Semantics

Human による差し戻し (Review Rejection) が発生し、新たな実行サイクルとして Claude Code が起動される際の振る舞いを以下に固定する。

1. **Authoritative Input**: Claude Code は、Manager によって指示が追記・更新された **最新の `task.md` 全体 (frontmatter + body)** を Authoritative Input (権威ある入力) として読み込む。
   - **Frontmatter**: `capabilities_required`, `approval_required`, `permission_mode`, `source_root_mode`, `status`, `job_id` 等の機械可読な制約の Source of Truth である。
   - **Body**: 自然言語による修正指示・コンテキストの補足である。
2. **既存 `result.md` の扱い**: Executor は過去の履歴を消さず、既存の `result.md` に今回のサイクルの結果を **追記 (Append)** する。
3. **`next_prompt.md` の状態**: Manager によって既に破棄 (Discard) されているという前提で開始し、準備が完了したタイミングで新規に生成する。

## 6. Signaling フローと Lock 管理

### Lock の生成 / 解放責務
- **生成**: Adapter Wrapper Layer が Claude Code 起動直前に `work/{job_id}.lock` を生成。
- **解放**: Claude Code 終了直後に Wrapper が確定で削除。

### Signaling Flow
- **stdout/stderr**: Wrapper が capture し、Manager へ中継。
- **`result.md`**: Claude Code が明示的に出力 (追記)。
- **`next_prompt.md`**: 自己検証成功時に Claude Code が明示的に新規生成。

## 7. Non-Goals (本フェーズでの対象外)

このフェーズでは以下の実装を行わない。
- ラッパースクリプト (.ps1) の実装や git hook の組み込み。
- 起動フラグの詳細な検証、具体的な System Prompt 記述や設定ファイルの生成。
