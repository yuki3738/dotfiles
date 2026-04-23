---
name: task-leak-check
description: |
  Slackメンション・Findy通知・HERP候補者メモ・GitHubレビュー依頼を横断して、南谷（@yuki3738）が対応し忘れている依頼・アクションを洗い出す「対応漏れリマインダー」。
  トリガー: "/task-leak-check [日数]" または「タスク漏れ」「依頼確認」「対応漏れ」「対応忘れ」「リマインダー」「やり残し」「対応してないやつ」などの発言でも使用する。
  使用場面: 朝イチで対応漏れを確認したいとき、休み明けの棚卸し、1on1や面談の合間のチェック、週末前の整理。
  他の面談・候補者系スキル（candidate-screen, interview-eval, selection-message, herp-scheduling）とは異なり、こちらは**個別の候補者を扱わず**、複数ソースを横断して「見落とし」を検出することに特化している。
argument-hint: "[日数（省略時は3）]"
---

# Task Leak Check

南谷（@yuki3738）が対応し忘れている依頼・アクションを以下の4ソースから横断的に洗い出す。

- **Slack メンション/DM**: 自分宛の依頼で未返信・未リアクションのもの
- **Findy 通知**（#activity-mov_findy = `C06UW1FMHEE`）: スクリーニング未完了のカジュアル面談候補者
- **HERP 候補者メモ**: 自分が担当者でメモが空の応募
- **GitHub レビュー依頼**（movinc org）: 個人/チームアサインで未対応のPR

## 引数

`$ARGUMENTS`: 遡る日数（整数、省略時は **3**）

例:
- `/task-leak-check` → 直近3日
- `/task-leak-check 7` → 直近7日

## 基本情報（固定値）

| 項目 | 値 |
|---|---|
| Slack user ID | `U0691F8E14P` |
| HERP operator ID | `U-L0EK3`（email: `y.minamiya@mov.am`） |
| Findy通知チャンネル ID | `C06UW1FMHEE` |
| GitHub ログイン | `yuki3738` |
| GitHub 対象org | `movinc` |
| movinc 所属チーム | `product`, `flamingo-fy2024`, `kaizen`, `hiring` |

## 手順

### 0. 前提確認

**MCP接続チェック**: 公式Slack MCP（`mcp__slack__*`）が疎通しているか `mcp__slack__channels_list` で確認する。
エラーが返ったら処理を始める前にユーザーに再接続を依頼する（事後に「未接続でした」と報告しない）。

引数を解釈し、`SINCE_DATE = 今日(JST) - N日` を計算する。

### 1. Slack メンション・DMの収集

公式Slack MCP（`mcp__slack__*`）を使用する。`mcp__claude_ai_Slack__*` は使わない。

#### 1-1. 自分宛メンションの検索
`mcp__slack__conversations_search_messages` で:
- `search_query`: `<@U0691F8E14P>`
- `filter_date_after`: `SINCE_DATE - 1日`（境界対策）
- `limit`: 100

パブリック/プライベート/スレッド内メンションが一括で取れる。

#### 1-2. DMの収集
`mcp__slack__conversations_search_messages` で:
- `filter_channel_types`: DM（ImまたはMpim）を指定するか、`search_query` に `in:dm` を付ける
- `filter_date_after`: `SINCE_DATE - 1日`

DMは自分がメンションされなくても「自分宛の依頼」として扱う。自分が発言しているものは除外する。

#### 1-3. 「対応済み」判定

各候補メッセージについて以下を判定し、**両方とも該当しない** ものを「要対応」として残す:

- **自分が同じスレッドに返信している**
  - `mcp__slack__conversations_replies` でスレッドを取得し、自分（`U0691F8E14P`）の投稿があるか確認
  - スレッドのないメッセージで、自分が同じチャンネル内で直後（目安10分以内）に関連発言している場合も返信とみなしてよい（判定が難しいのでスキップしても可）
- **自分が対象メッセージにemoji reactionを付けている**
  - メッセージの `reactions` フィールドをチェックし、`users` に `U0691F8E14P` が含まれるものがあれば対応済み
  - 種類は問わない（✅👀🙏👍🎉 などを区別しない。「見た」の意思表示として全て完了扱い）

#### 1-4. 自分発の通知やbotを除外

- bot_idがついたメッセージのうち、Findy/GitHub/HERP通知以外のノイズ（カレンダー通知、zapier 等）は除外
- 自分の発言は除外（`user == U0691F8E14P`）

### 2. Findy 通知（`C06UW1FMHEE` 内）

`mcp__slack__conversations_history` または `mcp__slack__conversations_search_messages` で channel `C06UW1FMHEE` の直近N日メッセージを取得する。

**判定ルール**:
- 「いいかも」通知の形式: メッセージ本文が **`○○○○（CANDIDATE_xxxxxx）さんから「いいかも」が届きました！`** で始まる
- 以下のいずれかで対応済み扱い:
  - 自分（`U0691F8E14P`）がそのメッセージにemoji reactionを付けている
  - 自分がそのスレッドに返信している
- 上記どちらもない通知を「要対応」として残す

### 3. HERP 候補者メモチェック

以下のスクリプトを実行する。`HERP_API_KEY` は `~/.env` に設定されている前提（`~/.zshrc` で `source ~/.env` されている）。

```bash
source ~/.env 2>/dev/null
ruby ~/.claude/skills/task-leak-check/scripts/herp_pending_memos.rb
```

結果はJSON。`count` が「active 応募のうちメモが空の件数」。

**背景**: 南谷はHERPの `operators` フィールドには設定されていない（operatorは成田・松岡・森・瀧川等の採用チーム）。EMとして全候補者を横断レビューしメモを書く立場のため、operator関係なく**全active候補者のうちメモ空の件数**を出す。
出力は件数のみ。一覧が必要な場合は `--verbose` を付ける。
HERPの候補者一覧URL: https://movinc.v1.herp.cloud/ats/p/candidacies

### 4. GitHub レビュー依頼

```bash
~/.claude/skills/task-leak-check/scripts/github_pending_reviews.sh
```

結果はJSON配列。各要素:
- `number`, `title`, `url`, `repository`, `author`, `updatedAt`, `assignedVia`

`assignedVia` は `personal` / `team:<team-slug>` / 両方のカンマ結合。

**既にApprove/Request Changes済みのPRはGitHubの仕様上review-requestedから外れるため、このリストに残っているものはすべて要アクション**（初回未レビュー＋再レビュー要求の両方を自然にカバーする）。

Draft PR はスクリプト側で除外済み。

### 5. 集計・出力

#### 5-1. チャット表示

以下のフォーマットで**ソース別セクション**に分けて出力する。各項目の末尾にURL（Slackはパーマリンク、GitHubはPR URL、HERPは候補者URL）を付ける。

````markdown
# 対応漏れチェック YYYY-MM-DD（過去N日）

## 💬 Slack メンション・DM（M件）

- [依頼内容の要約]（#channel-name / 送信者 / 日時）
  - <Slackパーマリンク>
- ...

## 🎯 Findy いいかも通知（未スクリーニング・M件）

- [候補者名]（CANDIDATE_xxxxxx / 日時）
  - <Slackパーマリンク>
- ...

## 📝 HERP メモ未入力候補者（M件）

- メモ未入力の active 応募: **M件**
- https://movinc.v1.herp.cloud/ats/p/candidacies

## 🔀 GitHub レビュー依頼（未対応・M件）

- **[repository #number]** [title]（author: xxx / アサイン: personal|team:xxx / 最終更新: YYYY-MM-DD）
  - <PR URL>
- ...

## サマリ
- Slack: M件 / Findy: M件 / HERP: M件 / GitHub: M件
- **合計 M件**
````

各ソースで0件の場合は「該当なし」と明記する（セクション自体は残す）。

#### 5-2. Obsidian ノートに保存

パス: `/Users/minamiyayuki/src/github.com/yuki3738/obsidian-vault/Private/Memo/task-leak/{YYYY-MM-DD}.md`

- ディレクトリが存在しなければ作成
- 既に同日のファイルがあれば**上書きではなく末尾に追記**（セッション複数回実行に対応、区切り `---\n## 再実行 HH:MM:SS\n` を入れる）
- frontmatter を付ける:

```yaml
---
date: YYYY-MM-DD
tags:
  - task-leak
  - reminder
range_days: N
total_count: M
---
```

- `total_count: 0` の場合もファイルは作成する（「0件だった」も記録として有用）
- **git commit/push はしない**。ユーザーが自分のタイミングで同期する前提。

### 6. 注意事項

- **ハルシネーション禁止**: Slack/Findy/HERP/GitHub のどれかでAPI/MCPエラーが出た場合、該当ソースは「取得失敗: エラーメッセージ」と明示し、空配列で扱わない（漏れた情報を「0件」と誤認させない）
- **個人情報の扱い**: Slack DMや候補者情報を含むため、生のメッセージ本文を全文引用せず、要約（1〜2行）にとどめる。ただし Obsidian 保存時はローカルなのでそのままで問題ない
- **敬称**: 候補者名は「○○さん」と表記する（候補者コミュニケーションルール準拠）
- **日付**: 全てJST基準。Slack APIのUnix timestampはJSTオフセット考慮
- **並列化**: ソースごとに独立しているので、Bash複数実行・MCP検索を**可能な限り並列で投げる**（ユーザーの待ち時間短縮）

## スクリプト一覧

| スクリプト | 用途 |
|---|---|
| `scripts/herp_pending_memos.rb` | HERP候補者のうち自分担当でメモ空のものをJSONで返す |
| `scripts/github_pending_reviews.sh` | GitHub movinc org のレビュー依頼PRをJSONで返す（個人+チーム、Draft除外、重複排除） |

## 参照

- 公式Slack MCP: `mcp__slack__*`（`mcp__slack__channels_list`, `conversations_search_messages`, `conversations_replies`, `conversations_history`）
- HERP Hire API: `https://public-api.herp.cloud/hire`（認証は `Bearer $HERP_API_KEY`）
- `gh search prs` コマンド（`--review-requested=@me` / `--review-requested=movinc/<team>`）
