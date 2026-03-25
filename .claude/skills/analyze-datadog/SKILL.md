---
name: analyze-datadog
description: Datadog（pup CLI）を使ってログ・ダッシュボード・APM・モニターを分析し、アプリケーションの改善を提案する。「Datadog分析」「ログ調査」「パフォーマンス分析」「モニター確認」などの発言でも使用する。
argument-hint: "<サブコマンド> [オプション] (例: logs status:error, dashboard <ID>, errors, performance, monitors)"
---

# Datadog 分析 & 改善提案

`pup` CLI を使って Datadog のログ・ダッシュボード・APM・エラートラッキング・モニターを分析し、コードベースと照合してアプリケーションの改善を提案します。

## Step 0: 認証の自動確認と復旧

**すべてのサブコマンドの実行前に、必ずこのステップを実行すること。**

### 1. 認証状態を確認

```bash
pup auth status -o json 2>&1
```

出力の `status` フィールドで判断する：

| status | 意味 | 次のアクション |
|--------|------|----------------|
| `authenticated` | 認証済み | → そのままサブコマンドに進む |
| `expired` | トークン期限切れ | → Step 0.2 へ |
| それ以外 | 未認証 | → Step 0.3 へ |

### 2. トークンの自動リフレッシュ（expired の場合）

`has_refresh: true` であれば自動リフレッシュを試みる：

```bash
pup auth refresh 2>&1
```

成功したら「認証をリフレッシュしました」と表示して、サブコマンドに進む。

失敗した場合は Step 0.3 へ。

### 3. ブラウザで再認証（リフレッシュ失敗 or 未認証の場合）

ユーザーに確認を取ってからブラウザ認証を実行する：

```bash
pup auth login
```

**注意**: ブラウザが開きユーザーの操作が必要。実行前に必ず「ブラウザで Datadog にログインしてください」と案内する。

ログイン完了後、再度ステータスを確認して `authenticated` になったことを検証する：

```bash
pup auth status -o json 2>&1
```

認証が成功しない場合は、以下を案内して中断する：
- 環境変数 `DD_SITE` が正しいか（デフォルト: `datadoghq.com`）
- VPN接続が必要ではないか
- Datadog のアカウント権限が十分か

## 引数

引数: `$ARGUMENTS`

### サブコマンド一覧

| サブコマンド | 説明 | 例 |
|-------------|------|-----|
| `logs <query>` | ログを検索・分析 | `logs status:error service:kutikomi` |
| `dashboard <ID>` | ダッシュボードの構成を分析 | `dashboard abc-def-123` |
| `errors` | エラートラッキングのイシューを分析 | `errors` |
| `performance` | APMサービスのパフォーマンスを分析 | `performance` |
| `monitors` | モニターのアラート状態を確認 | `monitors` |
| `investigate <キーワード>` | 横断的に調査（ログ＋APM＋エラー） | `investigate timeout` |

引数が空の場合は、上記のサブコマンド一覧を表示してユーザーに選択させる。

---

## サブコマンド: `logs`

### Step 1: ログを検索

```bash
# エラーログを検索（デフォルト: 直近1時間）
pup logs search --query="<query>" --from="1h" -o json

# 件数が多い場合は集計
pup logs aggregate --query="<query>" --from="1h" --compute="count" --group-by="service"
pup logs aggregate --query="<query>" --from="1h" --compute="count" --group-by="status"
```

**よく使うクエリ例:**

| 目的 | クエリ |
|------|--------|
| エラーログ全体 | `status:error` |
| 特定サービスのエラー | `status:error service:kutikomi-web` |
| タイムアウト | `status:error timeout` |
| 特定エンドポイント | `@http.url_details.path:/api/v1/*` |
| 遅いリクエスト | `@duration:>5000000000` |
| Sidekiqジョブ失敗 | `status:error service:kutikomi-sidekiq` |

### Step 2: ログの傾向を分析

- エラーの発生パターン（時間帯、頻度）
- 共通するエラーメッセージやスタックトレース
- 影響を受けているサービス・エンドポイント

### Step 3: コードベースを調査

ログのエラーメッセージやスタックトレースから、関連するコードを特定する：

- `app/controllers/` — エンドポイントの処理
- `app/usecases/` — ビジネスロジック
- `app/jobs/` — Sidekiqジョブ
- `lib/` — ライブラリ・外部API連携

---

## サブコマンド: `dashboard`

### Step 1: ダッシュボード一覧を取得（IDが不明な場合）

```bash
pup dashboards list -o json
```

一覧から関連するダッシュボードをユーザーに提示して選択させる。

### Step 2: ダッシュボードの詳細を取得

```bash
pup dashboards get <dashboard_id> -o json
```

### Step 3: ウィジェットを分析

ダッシュボードの各ウィジェットから以下を読み取る：

- **監視対象のメトリクス**: どんな指標が可視化されているか
- **クエリ内容**: どんな条件で絞り込んでいるか
- **閾値・アラート**: 設定されている閾値は適切か
- **不足している監視**: 追加すべきウィジェットはないか

### Step 4: メトリクスの現在値を確認

ダッシュボードで使われているメトリクスの現在値を取得：

```bash
pup metrics query --query="<メトリクスクエリ>" --from="1h" --to="now" -o json
```

### Step 5: 改善提案

- 監視が不足している領域の指摘
- 閾値の見直し提案
- 追加すべきウィジェットの提案

---

## サブコマンド: `errors`

### Step 1: エラーイシューを検索

```bash
pup error-tracking issues search -o json
```

### Step 2: 重要なイシューの詳細を確認

```bash
pup error-tracking issues get <issue_id> -o json
```

### Step 3: コードベースと照合

エラーのスタックトレースから該当コードを特定し、修正案を提示する。

**Railsアプリの一般的なエラーパターン:**

| エラー種別 | 調査ポイント |
|-----------|-------------|
| `NoMethodError` | nil チェック漏れ、関連付け未読み込み |
| `ActiveRecord::RecordNotFound` | find vs find_by、存在確認ロジック |
| `Timeout::Error` | 外部API呼び出し、N+1クエリ |
| `Redis::*Error` | Sidekiq設定、キャッシュ設定 |
| `Net::*Error` | 外部サービス接続、リトライ設定 |

---

## サブコマンド: `performance`

### Step 1: サービス一覧とパフォーマンス統計を取得

```bash
# 直近1時間のサービス統計
pup apm services stats --start $(date -v-1H +%s) --end $(date +%s) -o json
```

### Step 2: 依存関係を確認

```bash
pup apm dependencies list --env production --start $(date -v-1H +%s) --end $(date +%s) -o json
```

### Step 3: フローマップを確認

```bash
pup apm flow-map get --env production --service kutikomi-web --start $(date -v-1H +%s) --end $(date +%s) -o json
```

### Step 4: パフォーマンスの問題を特定

以下の観点で分析する：

- **レイテンシが高いサービス**: p50, p95, p99 の確認
- **エラー率が高いサービス**: エラー件数/総リクエスト数
- **スループットの異常**: リクエスト数の急増・急減
- **依存サービスのボトルネック**: 外部API、DB、Redis の応答時間

### Step 5: コードベースと照合

遅いエンドポイントやエラーが多いサービスのコードを確認：

- N+1 クエリの有無（`includes` の不足）
- 外部API呼び出しのタイムアウト設定
- キャッシュの活用状況
- Sidekiqへの非同期化の余地

---

## サブコマンド: `monitors`

### Step 1: モニター一覧を取得

```bash
pup monitors list -o json
```

### Step 2: アラート中のモニターを確認

出力から `state` が `Alert` または `Warn` のモニターを抽出する。

### Step 3: 特定モニターの詳細を確認

```bash
pup monitors get <monitor_id> -o json
```

### Step 4: モニター設定の評価

- **閾値は適切か**: 誤報が多い場合は閾値の緩和を提案
- **通知先は適切か**: チームの Slack チャンネルに通知されているか
- **不足しているモニター**: 監視すべき項目が漏れていないか

---

## サブコマンド: `investigate`

キーワードを元に横断的に調査する。

### Step 1: ログから調査

```bash
pup logs search --query="status:error <keyword>" --from="4h" -o json
pup logs aggregate --query="status:error <keyword>" --from="4h" --compute="count" --group-by="service"
```

### Step 2: エラートラッキングから調査

```bash
pup error-tracking issues search -o json
```

出力からキーワードに関連するイシューを抽出。

### Step 3: APMから調査

```bash
pup apm services stats --start $(date -v-4H +%s) --end $(date +%s) -o json
```

エラー率やレイテンシに異常があるサービスを特定。

### Step 4: 総合分析

各データソースの情報を突き合わせて、問題の全体像を把握する。

---

## 報告フォーマット

調査完了後、以下の形式でまとめる：

```markdown
## Datadog 分析レポート

### 調査概要
- **調査対象**: <サブコマンドと条件>
- **調査期間**: <時間範囲>
- **調査日時**: <実行日時>

### 検出された問題

#### 問題 1: <問題のタイトル>
- **深刻度**: Critical / High / Medium / Low
- **発生頻度**: <件数/期間>
- **影響範囲**: <サービス・エンドポイント>
- **関連コード**: <ファイルパス:行番号>
- **詳細**: <問題の説明>
- **推奨対応**:
  - <具体的な修正案>
  - <コード例があれば記載>

### 改善提案

#### 提案 1: <提案のタイトル>
- **カテゴリ**: パフォーマンス / 信頼性 / 監視 / セキュリティ
- **優先度**: High / Medium / Low
- **対象コード**: <ファイルパス>
- **内容**: <提案の詳細>
- **期待効果**: <改善による効果>

### 次のアクション
- [ ] <具体的なアクションアイテム>
```

## 注意事項

- **推測で結論を出さない**: データが不十分な場合は追加調査を提案
- **本番環境への影響を考慮**: 変更提案は影響範囲を明確にする
- **Sentryとの連携**: エラーの詳細調査が必要な場合は `/investigate-sentry` の併用を推奨
- **`pup` の出力が大きい場合**: JSON出力を `jq` でフィルタして必要な情報のみ取得する
- **時間範囲**: デフォルトは直近1時間。必要に応じてユーザーに期間を確認する
