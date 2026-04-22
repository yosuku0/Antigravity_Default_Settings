# Task: Multi-CLI Orchestration Contract (Milestone 2)

本ジョブは各フェーズの承認を経て進行する。現在は Phase D の Implementation & Integration (Claude Code 最小スライス) の最終統合をやり直している。

## Phase A: Design Freeze (Approved)
## Phase B: Contract Docs Authoring (Approved)
## Phase C: Adapter Design (Claude Code) (Approved)

## Phase D: Implementation & Integration (Current Focus: 完了承認待ち)
*着手条件: Phase C の承認完了*

### 1. 実装済み (Implemented)
- [x] **Templates**: `work/` テンプレート作成 (Schema 完全準拠)
- [x] **CLI Launch**: `npx` 経由の起動と出力キャプチャ
- [x] **Lock**: 競合検知と `finally` による確実な解放
- [x] **Enforcement (暫定)**: `ReadOnly` 属性による暫定保護 (Not Sandbox, Bitwise 制御)
- [x] **Enforcement (物理)**: Git `pre-push` hook による一連 of 物理遮断サイクル (Marker 管理, Fail-closed)
- [x] **Discard**: 起動時の stale `next_prompt.md` 物理削除
- [x] **Closed Loop Validator (Robust)**: `job_id` 監査および **Frontmatter-safe な status 自動更新 (v5)**

### 2. 実証済み (Verified / Evidence Provided)
- [x] **Evidence (Success Path)**: `test_integration_success/` にて `status: review` への遷移を実証
- [x] **Evidence (Failure Path)**: `test_integration_failure/` にて ID 不一致による `status: failed` への遷移を実証
- [x] **Fail-closed Hook**: 既存フック存在時の起動拒否ログ取得済み
- [x] **Evidence**: ReadOnly 保護および Git Push 遮断の実証済み

### 3. 未実装 / 次フェーズ課題 (Backlog)
- [ ] **Enforcement (High)**: サンドボックスによる完全な物理隔離
- [ ] **Production Integration**: プロトタイプ実装を本番オーケストレーションハンドラーへ統合

## Phase E: Additional CLI Adapters (未着手)
- [ ] 他の CLI エグゼキューターへの拡張
