#!/bin/bash
set -euo pipefail

LOG_PREFIX="[1on1-sync $(date '+%Y-%m-%d %H:%M:%S')]"
echo "${LOG_PREFIX} Starting 1on1 auto-sync..."

cd /Users/minamiyayuki/src/github.com/yuki3738/obsidian-vault

/Users/minamiyayuki/.local/bin/claude -p --no-session-persistence --max-turns 30 \
  "今日の1on1をすべてsyncして。
手順:
1. Google Calendarで今日の '1on1' イベントを検索(condenseEventDetails=falseで添付ファイル情報を取得)
2. 各イベントの添付ファイルから 'Gemini によるメモ' (title含む) のfileIdを取得
3. gog drive download でテキスト取得
4. Geminiヘッダー/フッター除去、見出しを##に、箇条書き*を-に変換してMarkdown整形
5. Work/mov/1on1/[名前]/YYYY-MM-DD.md に保存。名前はカレンダーのイベント名から判定し、既存ディレクトリとマッチさせる
6. 既にファイルが存在する場合はスキップ
7. 全件保存後 git add, commit, push
8. 1on1イベントが0件なら何もせず終了

重要:
- 対話的な確認は一切不要。すべて自動で判断すること
- Geminiメモのみ使用し、手動メモは無視
- 添付ファイルがないイベントはスキップ"

EXIT_CODE=$?
echo "${LOG_PREFIX} Finished with exit code ${EXIT_CODE}"
exit ${EXIT_CODE}
