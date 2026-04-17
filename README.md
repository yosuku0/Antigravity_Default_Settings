# Antigravity Default Settings

Antigravity環境における「コンテキスト汚染を防ぎ、自律的なエージェント駆動開発（Agentic Coding）を安定させるための標準作業ディレクトリ構成」を提供するテンプレートリポジトリです。本リポジトリは GitHub 等から Clone して配置するだけで、どこでも標準環境を再現できます。

## 解決する課題
1. **コンテキスト超過の防止**: プロジェクトの文脈を持たないグローバルスキルと、プロジェクト固有のスキルを明確に分離します。
2. **再現性の担保**: Git管理外にある `upstream` スキル群を安全に抽出し、手動で `active_*` に昇格（promote）させる一本化されたパイプラインを提供します。
3. **AIへの「読み込み順」の強制**: 開発開始時に読み込ませるべきドキュメント（`project-context.md` → `current-focus.md` → `tasks/README.md`）の雛形を提供します。

## 前提環境
- Windows (Powershell) / WSL2 
- Git がインストールされていること

## 導入手順

### 1. リポジトリの配置
このリポジトリをメインの開発ドライブのお好きな場所（例: `F:\AntigravityLab` 等）に Clone します。スクリプトは配置されたディレクトリをルートとして動作します。

```powershell
git clone https://github.com/yosuku0/Antigravity_Default_Settings.git F:\AntigravityLab
cd F:\AntigravityLab
```

### 2. 初期セットアップ
```powershell
.\scripts\initial-setup.ps1
```
ディレクトリ空間の生成、Upstreamリポジトリの取得が行われます。（この時点ではスキルは有効化されていません。また、2度目以降の実行でも既存ファイルは保護されます。）

### 3. スキルの有効化（Promote）
```powershell
.\scripts\promote-runtime-assets.ps1
```
必要なガードレールやワークフローが `runtime/active_*/` に配置されます。（既存を強制上書きする場合は `-Force` を付与してください。）`runtime/manifest.md` は Antigravity root marker としても機能します。

### 4. 検証
```powershell
.\scripts\validate-runtime.ps1
```
環境が正しく構築されたか、全24項目の検証が行われます。他プロセスから読む場合は `-Json` オプションを付けて実行してください。

## 新規プロジェクトの開始方法
`projects/_template` ディレクトリをコピーして新しいプロジェクトを作成し、`.agent/` 以下のファイルを埋めてください。

```powershell
Copy-Item "projects\_template" "projects\my-new-project" -Recurse
notepad projects\my-new-project\.agent\project-context.md
```

## Upstreamリポジトリの更新運用
具体的な更新・再展開の手順については、運用マニュアルである `runtime/runbook.md` を参照してください。

## 制約事項
- Hooks や MCP（Model Context Protocol）の連携は本バージョンの対象外です。