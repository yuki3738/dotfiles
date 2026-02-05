# Claude Code Configuration

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) のグローバル設定を管理するディレクトリ。
dotfilesリポジトリで管理し、シンボリックリンクで `~/.claude/` に展開して使用する。

## 構成

```
.claude/
├── CLAUDE.md                      # グローバル指示
├── settings.json                  # hooks・プラグイン設定
├── agents/                        # カスタムエージェント
│   ├── api-designer.md
│   ├── code-debugger.md
│   ├── code-reviewer.md
│   ├── error-detective.md
│   ├── git-workflow-manager.md
│   └── rails-expert.md
├── skills/                        # カスタムスキル（/コマンド）
│   ├── add-knowledge/
│   ├── codex/
│   ├── parallel-worktrees/
│   ├── pr-top-comment/
│   ├── review-cycle/
│   ├── rspec-fill/
│   ├── rspec-refactor/
│   ├── rubocop-fix/
│   ├── rubocop-todo-fix/
│   ├── security-review/
│   ├── settings-summary/
│   └── worktree/
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
| `add-knowledge` | CLAUDE.local.mdに知見を追記 |
| `codex` | Codex CLIでコードレビュー・相談 |
| `parallel-worktrees` | 並列作業用のgit worktreeセットアップ |
| `pr-top-comment` | PRトップコメント生成 |
| `review-cycle` | レビューサイクル |
| `rspec-fill` | 不足RSpecテストの補完 |
| `rspec-refactor` | RSpecリファクタリング |
| `rubocop-fix` | RuboCop違反の修正 |
| `rubocop-todo-fix` | rubocop_todo.yml解消 & PR作成 |
| `security-review` | セキュリティレビュー |
| `settings-summary` | 設定一覧をMY_SETTINGS.mdに出力 |
| `worktree` | git worktreeセットアップ |

### hooks/

- `notify-completion.sh` - タスク完了時にシステム音を再生
- `notify-selection.sh` - 選択肢提示時に通知

## セットアップ

```bash
# dotfilesリポジトリをクローン
ghq get yuki3738/dotfiles

# 各ファイルを ~/.claude/ にシンボリックリンク
ln -sf ~/src/github.com/yuki3738/dotfiles/.claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -sf ~/src/github.com/yuki3738/dotfiles/.claude/settings.json ~/.claude/settings.json
ln -sf ~/src/github.com/yuki3738/dotfiles/.claude/agents ~/.claude/agents
ln -sf ~/src/github.com/yuki3738/dotfiles/.claude/skills ~/.claude/skills
ln -sf ~/src/github.com/yuki3738/dotfiles/.claude/hooks ~/.claude/hooks
```
