---
name: settings-summary
description: Claude Code設定の全体像をまとめて~/.claude/MY_SETTINGS.mdに出力
---

現在のClaude Code設定を調査し、まとめを作成してください。

## 調査対象

### グローバル設定 (~/.claude/)
1. `~/.claude/CLAUDE.md` - 全プロジェクト共通ルール
2. `~/.claude/commands/` - グローバルコマンド一覧
3. `~/.claude/skills/` - グローバルスキル一覧
4. `~/.claude.json` の `mcpServers` - MCP サーバー一覧
5. `~/.claude.json` の設定（editorMode, theme等）

### プロジェクト設定 (.claude/)
1. `.claude/CLAUDE.md` - プロジェクト固有ルール
2. `.claude/commands/` - プロジェクトコマンド一覧
3. `.claude/skills/` - プロジェクトスキル一覧
4. `.claude/settings.json` の `enabledPlugins` - インストール済みプラグイン

## 出力形式

以下の構成でMarkdownファイルを作成:

```markdown
# Claude Code 設定まとめ

最終更新: [今日の日付]

## グローバル設定
### CLAUDE.md（要約）
### コマンド一覧（テーブル形式）
### スキル一覧
### MCP サーバー一覧（テーブル形式）

## プロジェクト設定（現在のプロジェクト名）
### CLAUDE.md（要約）
### コマンド一覧
### プラグイン一覧（テーブル形式）

## その他の設定
## 参考リンク
## Tips
```

## 出力先

`~/.claude/MY_SETTINGS.md` に上書き保存

## 注意事項

- 各コマンド/スキルの説明は簡潔に（1行以内）
- プラグインはPR番号があれば記載
- 設定の優先順位についてのTipsを含める
