---
name: flamingo-retro
description: |
  Flamingoチームの週次ふりかえり用に、直近1週間の活動状況をまとめる。
  トリガー: "/flamingo-retro" または "/flamingo-retro <YYYY-MM-DD>"
  使用場面: Flamingoチームの週次ふりかえり前の準備
---

# Flamingo Retro

Flamingoチームの直近1週間の活動をGitHub・Slackから収集し、ふりかえり用サマリーを生成する。

## チーム情報

- **GitHub Team**: movinc/flamingo
- **メンバー**:

| GitHub | 名前 | 備考 |
|--------|------|------|
| sotarofujimaki | 藤牧 宗太郎 | リード候補。DevOps含めチーム全体を見れる状態を目指す |
| YutaKato3548 | 加藤 | 不確実性の高い課題にもチームを引っ張れるようにする |
| yodakaEngineer | よだか | 自発的に動ける状態を目指す |
| k-shogo | 川口 | 技術的強みを組織に伝播させる |
| mtkasima | kasima | - |
| yusuke-ogaki | 大垣 | - |

- **主要リポジトリ**: kutikomi-com, kutikomi-lab, kutikomi-com-terraform, kutikomi-com-searches, kutikomi-academy

### Four Keys データソース（kutikomi-com）

| メトリクス | データソース | 計算方法 |
|---|---|---|
| デプロイ頻度 | `deploy-main` workflow (ID: 35891476) の success runs | 期間内の成功回数 |
| リードタイム | チームメンバーのPR `createdAt` → `mergedAt` | 中央値 |
| 変更障害率 | `rollback-ecs-services` workflow (ID: 157655308) + revert PR | rollback回数 / デプロイ数 |
| MTTR | rollback実行からサービス復旧（次の成功deploy）まで | 推定値 |

## 引数

`$ARGUMENTS` のフォーマット: `<YYYY-MM-DD>` （任意、省略時は今日）

指定日を基準に、その日を含む直近1週間（7日前〜当日）を対象とする。

## 手順

### 0. 対象期間の決定

- `$ARGUMENTS` に日付があればその日を END_DATE、なければ今日
- START_DATE = END_DATE - 6日
- 表示: `{START_DATE} 〜 {END_DATE}`

### 1. GitHub活動の収集

**メンバーごと**に以下を並列で収集する。Agentを活用して効率化すること。

#### 1-1. PR（作成）

```bash
gh search prs --author={login} --created="{START_DATE}..{END_DATE}" --owner=movinc --limit=50 --json title,url,state,createdAt,repository,additions,deletions --sort=created
```

#### 1-2. PR（レビュー）

```bash
gh search prs --reviewed-by={login} --created="{START_DATE}..{END_DATE}" --owner=movinc --limit=50 --json title,url,state,createdAt,repository,author --sort=created
```

- 自分が作成したPRがレビュー一覧に含まれる場合は除外する

#### 1-3. PRコメント（レビューコメント）

```bash
gh api search/issues --method GET -f q="type:pr commenter:{login} org:movinc created:{START_DATE}..{END_DATE}" -f per_page=30 --jq '.items[] | {title: .title, url: .html_url, repository: .repository_url}'
```

### 2. Slack活動の収集（Slack MCPが利用可能な場合のみ）

Slack MCPツール（`mcp__slack__*`）が利用可能な場合のみ実行する。利用不可ならスキップ。

- `mcp__slack__conversations_search_messages` で `#kcom_dev` チャンネルの直近1週間のメッセージを検索
- Flamingoメンバーの発言や言及を抽出
- 技術的議論、課題共有、意思決定に関する内容を要約

### 3. ふりかえり用1on1ノート確認

`Private/1on1/` 配下で対象期間内に更新されたFlamingoメンバーの1on1ノートがあれば読み込む。

```bash
find Private/1on1 -name "*.md" -newer "{START_DATE相当のファイル}" 2>/dev/null
```

各ノートから、チーム活動に関連するトピックを抽出する（個人的な内容は含めない）。

### 4. Four Keys メトリクスの収集（Flamingo限定）

Four KeysはFlamingoメンバーのPRに起因するデプロイのみを対象とする。

#### 4-0. FlamingoメンバーのマージPR番号リストを作成

まず、期間内にFlamingoメンバーがkutikomi-comでマージしたPRの番号を全件取得する:

```bash
for login in sotarofujimaki YutaKato3548 yodakaEngineer k-shogo mtkasima yusuke-ogaki; do
  gh pr list --repo movinc/kutikomi-com --state merged --search "created:{START_DATE}..{END_DATE} author:$login" --limit=50 --json number,author --jq '.[] | "\(.number) \(.author.login)"'
done
```

このPR番号リスト（以下 `FLAMINGO_PR_NUMBERS`）を後続ステップで使う。

#### 4-1. デプロイ頻度（Deployment Frequency）

kutikomi-com の `deploy-main` ワークフロー成功runを全件取得し、`display_title` に含まれるPR番号が `FLAMINGO_PR_NUMBERS` に一致するものだけカウントする:

```bash
# ページネーションして全件取得（per_page=100、page=1,2,...）
gh api "repos/movinc/kutikomi-com/actions/workflows/35891476/runs?created={START_DATE}..{END_DATE}&status=success&branch=main&per_page=100&page={N}" --jq '[.workflow_runs[] | {display_title, created_at}]'
```

display_title から `#(\d+)` を正規表現で抽出し、FLAMINGO_PR_NUMBERSと照合する。
一致したrunの数 = Flamingoチームのデプロイ回数。

参考値として全体デプロイ数（`.total_count`）も記録する。

DORA基準での評価:
- Elite: 1日複数回 / High: 1日1回〜週1回 / Medium: 週1回〜月1回 / Low: 月1回未満

#### 4-2. リードタイム（Lead Time for Changes）

チームメンバーのマージ済みPR全件の `createdAt` → `mergedAt` の差分を計算し、中央値を算出:

```bash
for login in sotarofujimaki YutaKato3548 yodakaEngineer k-shogo mtkasima yusuke-ogaki; do
  gh pr list --repo movinc/kutikomi-com --state merged --search "created:{START_DATE}..{END_DATE} author:$login" --limit=50 --json title,createdAt,mergedAt,author
done
```

全メンバー分を集約して中央値を算出する。

DORA基準: Elite: <1時間 / High: 1日〜1週間 / Medium: 1週間〜1ヶ月 / Low: 1ヶ月超

#### 4-3. 変更障害率（Change Failure Rate）

FlamingoメンバーのrevertPR + Flamingoが原因のrollbackをカウント:

```bash
# FlamingoメンバーのrevertPR
for login in sotarofujimaki YutaKato3548 yodakaEngineer k-shogo mtkasima yusuke-ogaki; do
  gh search prs --author=$login --repo=movinc/kutikomi-com --created="{START_DATE}..{END_DATE}" --limit=50 --json title
done
# → title に "revert" を含むものをカウント

# rollback実行（全体）— Flamingoのデプロイが原因かは display_title のPR番号で判定
gh api "repos/movinc/kutikomi-com/actions/workflows/157655308/runs?created={START_DATE}..{END_DATE}&per_page=100" --jq '.workflow_runs[] | {created_at, conclusion, display_title}'
```

変更障害率 = (Flamingo起因のrollback + revert PR数) / Flamingoデプロイ数

DORA基準: Elite: 0-5% / High: 5-10% / Medium: 10-15% / Low: 15%超

#### 4-4. MTTR（Mean Time to Recovery）

Flamingoが原因のrollbackがあった場合、rollback実行時刻と直後の成功デプロイ時刻の差分から推定。
障害がない週は「障害なし」と記載。

DORA基準: Elite: <1時間 / High: <1日 / Medium: 1日〜1週間 / Low: 1週間超

### 5. 分析・集計

#### 4-1. メンバー別活動サマリー

メンバーごとに:
- PR作成数・マージ数
- レビュー数
- 主な取り組みテーマ（PRタイトルから推定）
- 注目すべきPR（大きな変更、新機能、リファクタリング）

#### 4-2. チーム全体の傾向

- 総PR数、総レビュー数
- 活発だったリポジトリ
- コラボレーションパターン（誰が誰のPRをレビューしているか）
- チーム目標との関連（North Starのフォーカスに照らして）

#### 4-3. North Star観点の評価

`brain/North Star.md` を読み、Flamingoチームに関する目標（自律化、藤牧リード等）に対して:
- 今週の活動がどう紐づくか
- 進捗や懸念があれば指摘

### 5. 出力フォーマット

以下のフォーマットでマークダウンを生成する:

````markdown
# Flamingo 週次ふりかえり: {START_DATE} 〜 {END_DATE}

## Four Keys（kutikomi-com / Flamingo限定）

| メトリクス | Flamingo | DORA評価 | 全体（参考） | 前週比 |
|---|---|---|---|---|
| デプロイ頻度 | {N}回/週（{N}回/日） | {Elite/High/Medium/Low} | {N}回/週 | {↑↓→} |
| リードタイム（中央値） | {N}時間 | {Elite/High/Medium/Low} | - | {↑↓→} |
| 変更障害率 | {N}% ({failure}/{deploy}) | {Elite/High/Medium/Low} | {N}% | {↑↓→} |
| MTTR | {N}時間 or 障害なし | {Elite/High/Medium/Low} | - | {↑↓→} |

> デプロイ頻度はFlamingoメンバーのPRマージに起因するデプロイのみカウント。全体はkutikomi-com全deploy-main成功数。
> 前週比は前週のふりかえりファイルが `Private/Weekly/` に存在する場合のみ表示。なければ「-」。

## チーム活動サマリー

- PR作成: {N}件（マージ済: {N}件）
- PRレビュー: {N}件
- 活発なリポジトリ: {repo1}, {repo2}

## メンバー別

### {名前}（@{login}）

**PR作成** ({N}件)
- [{title}]({url}) — {state} (+{additions}/-{deletions})
- ...

**レビュー** ({N}件)
- [{title}]({url}) — by @{author}
- ...

**今週の動き**
- {PRタイトルやSlack活動から読み取れる取り組みの要約}

---

（全メンバー分繰り返す）

## コラボレーション

- レビュー関係: 誰が誰のPRを見ているかのサマリー
- クロスレビューが少ない場合はフラグ

## North Star との照合

- **藤牧のリード**: {今週の評価}
- **加藤の不確実性対応**: {今週の評価}
- **よだかの自発性**: {今週の評価}

## Sailboat Retrospective

今週のデータ（Four Keys、PR活動、レビュー関係、North Star照合）から読み取れる内容をセイルボートの4象限に分類する。
データに裏付けのある具体的な事実をベースに書く。推測は最小限にとどめる。

### 🏝️ Island（目的地）
_チームが向かっている先。North Starから引用。_

- {North Starに記載のFlamingoチーム目標}

### 💨 Wind（追い風）
_チームを前に進めている力。今週のデータから。_

- {具体的な事実: PR数、レビュー活動、Four Keysの良い指標、メンバーの成長兆候など}

### ⚓ Anchor（錨）
_チームの足を引っ張っている要因。今週のデータから。_

- {具体的な事実: リードタイムの長さ、レビューの偏り、特定領域への集中、クロスレビュー不足など}

### 🪨 Rocks（岩礁）
_今後のリスク・障害。今週の傾向から予測されるもの。_

- {今週の活動から見えるリスク: Open PRの滞留、特定メンバーへの依存、スコープの分散など}

## ふりかえりで話したいこと

上記Sailboatの各象限から、特にチームで議論すべきトピックをピックアップ:

- {議論ポイント1}
- {議論ポイント2}
````

### 6. ファイルの保存

- **保存先**: `Private/Weekly/{YYYY}/flamingo-retro-{END_DATE}.md`
- ディレクトリが存在しない場合は作成する

### 7. Git commit

```bash
cd /Users/minamiyayuki/src/github.com/yuki3738/obsidian-vault
git add "Private/Weekly/{YYYY}/flamingo-retro-{END_DATE}.md"
git commit -m "docs: add Flamingo weekly retro {END_DATE}"
```

push はしない（ユーザーに任せる）。

## 注意事項

- GitHub APIのレート制限に注意。メンバー6人×3クエリ = 最大18リクエスト
- PRが多い週は主要なもの（大きな変更、新機能）を優先して詳述し、小さなものはリスト化
- 1on1の個人的内容（キャリア、評価等）はふりかえり資料に含めない
- メンバーの活動量を単純比較しない。量より質・インパクトに着目する
- 出力はターミナルにもレンダリング前のmarkdown表記で表示する
