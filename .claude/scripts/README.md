# Claude Code 自動化スクリプト

## 1on1-auto-sync.sh

毎日23:03に実行され、その日のGoogle Calendar上の1on1イベントからGemini議事録を取得し、Obsidian vaultへ保存・git pushする。

### 仕組み

- **launchd plist**: `~/Library/LaunchAgents/com.claude.1on1-sync.plist`
- **ログ**: `~/.claude/logs/1on1-sync.log`
- **保存先**: `obsidian-vault/Work/mov/1on1/[名前]/YYYY-MM-DD.md`

内部では `claude -p`（非対話モード）でClaude Codeを起動し、Google Calendar MCP → gog drive download → Markdown整形 → git push の一連の処理を自動実行する。

### 操作

```bash
# 手動実行
bash ~/.claude/scripts/1on1-auto-sync.sh

# ログ確認
cat ~/.claude/logs/1on1-sync.log

# 停止
launchctl unload ~/Library/LaunchAgents/com.claude.1on1-sync.plist

# 再開
launchctl load ~/Library/LaunchAgents/com.claude.1on1-sync.plist

# 状態確認
launchctl list | grep 1on1
```
