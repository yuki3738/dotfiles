# Claude Code Configuration

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) のグローバル設定を管理するディレクトリ。
dotfilesリポジトリで管理し、シンボリックリンクで `~/.claude/` に展開して使用する。

## 構成

```
.claude/
├── CLAUDE.md                      # グローバル指示
├── settings.json                  # hooks・プラグイン設定
├── agents/                        # カスタムエージェント
│   ├── code-debugger.md
│   ├── code-reviewer.md
│   ├── error-detective.md
│   ├── git-workflow-manager.md
│   └── rails-expert.md
├── skills/                        # カスタムスキル（/コマンド）— 一覧は `ls ~/.claude/skills/`
├── scripts/                       # 自動化スクリプト
│   └── 1on1-auto-sync.sh
└── hooks/                         # イベントフック
    ├── notify-completion.sh
    └── notify-selection.sh
```

## 各設定の説明

### CLAUDE.md

全プロジェクト共通のグローバル指示。言語設定、エラー対応の原則、テスト失敗時のルールなどを定義。

### settings.json

- **Stop hook**: タスク完了時に通知音を再生
- **Notification hook**: ツール使用許可リクエスト時に通知
- **プラグイン**: Slack連携

### agents/

Task toolで使用する専門エージェント。コードレビュー、デバッグ、Rails開発、API設計など。

> Based on [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) (MIT License)

### skills/

`/コマンド名` で呼び出せるカスタムスキル。

最新の一覧は以下で確認:

```bash
ls ~/.claude/skills/
```

各スキルの説明・トリガー条件は `~/.claude/skills/<skill-name>/SKILL.md` の frontmatter (`description` フィールド) を参照。Claude Code起動中は自動で読み込まれているので、`/<skill-name>` で直接呼び出せる。

### scripts/

- `1on1-auto-sync.sh` - launchdで毎日実行。Google CalendarのGemini議事録をObsidian vaultへ自動同期

### hooks/

- `notify-completion.sh` - タスク完了時にシステム音を再生
- `notify-selection.sh` - 選択肢提示時に通知

## セットアップ

`setup.sh` が `.claude/` ディレクトリごと `~/.claude` にシンボリックリンクを作成するため、個別のリンク設定は不要。

```bash
cd ~/src/github.com/yuki3738/dotfiles
./setup.sh
```

### 依存ツール（Google Workspace 連携 skills 用）

`1on1-sync` / `casual-interview-sync` / `daily-report` / `flamingo-retro-sync` / `interview-eval` / `meeting-summary` は **`gws` CLI**（[googleworkspace/cli](https://github.com/googleworkspace/cli)）に依存する。Drive / Docs / Calendar / Gmail などの操作に使用。

```bash
# 1. gcloud SDK（gws auth setup の前提）
brew install --cask gcloud-cli

# 2. gws 本体
brew install googleworkspace-cli

# 3. 初回認証（gcloud → gws の順）
gcloud auth login y.minamiya@mov.am
gws auth setup --login
```

認証完了後 `gws auth status` で `token_valid: true` と enabled APIs が表示されれば OK。

トラブルシュート:
- `invalid_grant` / `Token has been expired`: `gws auth login` で再認証
- スコープ不足: `gws auth login --services drive,docs,gmail,calendar` で必要なAPIを指定して再ログイン
- `gws drive files export --output ...` が `outside the current directory` エラー: 出力先は cwd 配下のみ。`cd /tmp && gws ... --output foo.md` の形にする
