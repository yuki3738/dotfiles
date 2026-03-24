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
├── skills/                        # カスタムスキル（/コマンド）
│   ├── 1on1-sync/
│   ├── add-knowledge/
│   ├── article-to-em-skill/
│   ├── bakuraku-ringi/
│   ├── candidate-screen/
│   ├── codex/
│   ├── em-coaching/
│   ├── em-growth-questioning/
│   ├── find-docs/
│   ├── interview-eval/
│   ├── parallel-worktrees/
│   ├── pr-top-comment/
│   ├── review-cycle/
│   ├── review-dependabot/
│   ├── rspec-fill/
│   ├── rspec-refactor/
│   ├── rubocop-batch/
│   ├── rubocop-fix/
│   ├── rubocop-todo-fix/
│   ├── security-review/
│   ├── selection-message/
│   ├── settings-summary/
│   └── worktree/
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

| スキル | 説明 |
|--------|------|
| `1on1-sync` | Google Docsの1on1議事録をObsidianに取り込み |
| `add-knowledge` | CLAUDE.local.mdに知見を追記 |
| `article-to-em-skill` | 記事からEM向けスキルを生成 |
| `bakuraku-ringi` | バクラクの稟議申請フォーム入力 |
| `candidate-screen` | 候補者プロフィールのスクリーニング |
| `codex` | Codex CLIでコードレビュー・相談 |
| `em-coaching` | EMとしての成長コーチング |
| `em-growth-questioning` | 成人発達理論に基づく問い設計 |
| `find-docs` | 技術ドキュメントの検索・取得 |
| `interview-eval` | 面接評価シートの入力文章生成 |
| `parallel-worktrees` | 並列作業用のgit worktreeセットアップ |
| `pr-top-comment` | PRトップコメント生成 |
| `review-cycle` | レビューサイクル |
| `review-dependabot` | Dependabotアラートのレビュー |
| `rspec-fill` | 不足RSpecテストの補完 |
| `rspec-refactor` | RSpecリファクタリング |
| `rubocop-batch` | 複数ファイルのRuboCop違反を並列解消 |
| `rubocop-fix` | RuboCop違反の修正 |
| `rubocop-todo-fix` | rubocop_todo.yml解消 & PR作成 |
| `security-review` | セキュリティレビュー |
| `selection-message` | カジュアル面談後の選考案内メッセージ生成 |
| `settings-summary` | 設定一覧をMY_SETTINGS.mdに出力 |
| `worktree` | git worktreeセットアップ |

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
