# Adapter Guide

本文書は、`Antigravity` オーケストレーション環境において、任意の CLI ツールを `Executor Contract` に適合させるための「Adapter」設計指針を定義する。

## 1. 3層分離アーキテクチャ (Three-Layer Architecture)

契約の ownership と境界を保護するため、Executor の実行環境は以下の 3 層に厳格に分離される。

1. **Model Layer (CLI 本体)**
   - 責務: 推論、自律操作、および Artifact (`result.md`, `next_prompt.md`) の Writer としての直接出力。
   - 制限: `task.md` は read-only とし、直接書き込んではならない。
2. **Adapter Wrapper Layer (ラッパースクリプト)**
   - 責務: Lock の生成・解放、CLI 起動管理、stdout/stderr および exit code の capture。
   - 制限: **Wrapper 自身は Artifact の Writer ではない**。`result.md` などの生成・補助は行わず、Model Layer へのプロンプト指示等を通じて CLI 本体に生成させる。禁止操作の fail-closed 制御（ネットワーク遮断やフックによる push ブロック等）を担当する。
3. **Manager Layer (オーケストレーション)**
   - 責務: `task.md` の更新、Artifact 検証 (`expected_artifacts` 充足判定など)、stale Artifact の Discard 例外実行、Review 判定。

## 2. Enforcement 原則 (権限保護の多層防御)

Adapter 設計においては、操作のリスクに応じた多層防御 (Defense in Depth) を必須とする。

- **低リスク操作 (`edit`, `test`)**: プロンプト制御 (System Prompt による Do/Don't 指示) を主体としてよい。ただし、Manager 所有ファイルと保護パスは例外的に厳重保護とする。
  - ※ 破壊的な上書きやファイル内容の全消去 (destructive overwrite / truncate) は単なる `edit` ではなく `delete` 相当の高リスク操作とみなし、Wrapper Layer / Sandbox によって防御される必要がある。
- **高リスク操作 (`delete`, `commit`, `push`, `network`)**: **プロンプトのみで制御してはならない**。必ず Wrapper、Sandbox、Hook、または Review Gate のいずれかによる **fail-closed な物理的・強制的ブロック機構** を設けること。
- **保護対象スコープ (`runtime/orchestration/**` 全体)**: Manager-Owned Files (`task.md` 等) に加え、すべての契約文書 (`contracts/**`) およびアダプター設計・ラッパー資産 (`adapters/**`) は静的参照資産であるため、Model Layer からは Read-Only として扱う。Wrapper Layer や Sandbox 設定においても **対象パス全体への Write を物理的に禁止** (fail-closed) すること。

## 3. 契約の厳格な遵守

いかなる Adapter 設計も、以下の禁止事項を迂回してはならない:
- **`task.md` の直接更新禁止**: Adapter および Model Layer が、Manager 所有の `task.md` に書き込む仕組みを作らないこと。
- **Signaling 制約**: 状態伝達はすべて `stdout/stderr`, `result.md`, `next_prompt.md` を経由して行うこと。
- **権限の再解釈禁止**: `approval_required` などの Execution Safety フィールドを勝手に緩めたり無視したりしないこと。

## 4. ディレクトリ構成と命名規則

- `runtime/orchestration/adapters/{cli-name}/`
  - `{CLI_NAME}_ADAPTER.md`: 対象 CLI 固有の Adapter 契約・マッピング設計書。
  - 今後の Phase D で追加されるプロンプトテンプレートやラッパースクリプトなども同ディレクトリに格納する。
