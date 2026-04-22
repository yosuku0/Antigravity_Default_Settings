# Task: Multi-CLI Orchestration Contract (Milestone 2)

本ジョブは各フェーズの承認を経て進行する。現在は Phase D の Repo 整合性回復と最終承認待ちの状態である。

## Phase A: Design Freeze (Approved)
## Phase B: Contract Docs Authoring (Approved)
## Phase C: Adapter Design (Claude Code) (Approved)

## Phase D: Implementation & Integration (Current Focus: 完了承認待ち / Repo 整合修正済み)
*着手条件: Phase C の承認完了*

### 1. 実装済み (Implemented)
- [x] **Templates**: `work/` テンプレート作成 (task/result/next_prompt すべて揃った状態)
- [x] **CLI Launch**: `npx` 経由の **実起動パス** 実装 (v8 Wrapper) および出力キャプチャ
- [x] **Lock**: 競合検知と `finally` による確実な解放
- [x] **Enforcement (暫定)**: `ReadOnly` 属性による暫定保護 (Bitwise 制御)
- [x] **Enforcement (物理)**: Git `pre-push` hook による物理遮断サイクル (Marker 管理, Fail-closed)
- [x] **Discard**: 起動時の stale `next_prompt.md` 物理削除
- [x] **Closed Loop Validator (Strict)**: `job_id` 監査および **suggested_action enum 監査** (v5)

### 2. 実証済み (Verified / Evidence Provided)
- [x] **Evidence (Repo-Local)**: `docs/evidence/phase-d/` 配下に成功・失敗の実ファイル証跡を永続化
- [x] **Success Path**: `docs/evidence/phase-d/success/` にて `status: review` への遷移を repo 内で監査可能
- [x] **Failure Path**: `docs/evidence/phase-d/failure/` にて ID 不一致による Reject を repo 内で監査可能
- [x] **Fail-closed Hook**: 既存フック存在時の起動拒否ログ取得済み

### 3. 未実装 / 次フェーズ課題 (Backlog)
- [ ] **Enforcement (High)**: サンドボックスによる完全な物理隔離
- [ ] **Production Integration**: プロトタイプ実装を本番オーケストレーションハンドラーへ統合

## Phase E: Additional CLI Adapters (未着手)
- [ ] 他の CLI エグゼキューターへの拡張
