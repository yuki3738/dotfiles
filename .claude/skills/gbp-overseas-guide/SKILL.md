---
name: gbp-overseas-guide
description: |
  kutikomi-com の GBP海外対応を中心に、関連する 6 領域（Searches多言語・競合分析・投稿機能・Facebook連携・デモデータ・AIエージェントAPI）の
  ドメインマップ・ハマりポイント・定型ワークフローをまとめたガイド。
  トリガー: "/gbp-overseas-guide" または「GBP海外」「competitor」「Searches多言語」「投稿locale」「demo:import」「ai_agent API」等の相談時
  使用場面:
    (1) 上記7領域のコードを触るとき
    (2) 実装方針に迷ったときの判断材料がほしいとき
    (3) 新人オンボーディングで当該ドメインの地図を渡したいとき
---

# Skill: GBP海外対応 + 関連ドメインガイド

## Overview

kutikomi-com 内で歴史的に密接に発展してきた以下 7 領域のドメイン知識を、関連 PR から抽出して形式知化したものです。
GBP海外対応がシグネチャ領域として大きいため、Skill名に採用しています。

- **配置**: `~/.claude/skills/gbp-overseas-guide/`（個人用Skill）
- **関連ドキュメント**: [kutikomi-com/docs/gmb/overseas.md](https://github.com/movinc/kutikomi-com/blob/main/docs/gmb/overseas.md) — GBP海外対応の詳細リファレンス（チーム公式資産）
- **更新方法**: 下部の「Skillの更新方法」を参照

> **Note**: GBP海外対応の詳細は `docs/gmb/overseas.md` に移管済み。本Skillは対話ガイド・チェックリストに特化。
> 他6領域は将来docs化予定。

## 対象ドメイン（7領域）

| # | 領域 | キーワード | 代表PR |
|---|------|-----------|--------|
| 1 | **GBP海外対応** | locality, region_code, language_code, 台湾/香港/韓国/タイ | #17497, #18731, #18774, #18892, #18953, #19332, #19722 |
| 2 | **Searches多言語** | post_kcom_searches_stores.locale, original_text, 国絞り込み | #13257, #13275, #19220, #19332, #19404 |
| 3 | **競合店舗・競合分析** | store_competitors, Competitor, 星の数分析, 相関分析 | #15736, #16088, #16481, #16504, #16920, #16779 |
| 4 | **投稿機能（Post）** | 繰り返し投稿, 公開終了予定日, 承認申請 | #15620, #15671, #17135, #17150, #17187 |
| 5 | **Facebook連携** | 再認証, 認証エラー通知, エラーハンドリング | #15393, #15430, #15517, #18074, #19138 |
| 6 | **デモデータ** | demo.yml, demo:import, lib/demo/*Builder, yaml駆動 | #12651, #12670, #12778, #13380, #16755 |
| 7 | **AIエージェントAPI** | ai_agent/配下, JWT+ClientCredential, mastra/n8n | #18228, #18329, #18504, #18537, #19047 |

---

## ドメインマップ（どこを触るか）

### 1. GBP海外対応

詳細は **[kutikomi-com/docs/gmb/overseas.md](https://github.com/movinc/kutikomi-com/blob/main/docs/gmb/overseas.md)** を参照（データモデル / 中核ファイル / 設定YAML / 方向別挙動 / 新国追加手順 / 参考PR）。

**即座に思い出したいときの要点**:
- 中核ファイル: `app/models/store/address.rb` / `app/models/gmb/commands/stores/fetch_basic_information_command.rb` / `app/models/gmb/representations/base_representation.rb`
- 設定: `config/settings/country_to_locale_mapping.yml` / `config/settings/locality_usable_country_list.yml`
- 対応国: JP / US / TW / HK / KR（+ TH 部分対応中）

### 2. Searches多言語 — データモデル

- **テーブル**: `post_kcom_searches_stores` (`locale` カラム default `"ja"`, UNIQUE (post_id, store_id, locale))
- **主要クラス**: `Post::KcomSearches::Store`
- **多言語ON/OFFフラグ**: `company_stocks.kcom_searches_multilingual_option`
- **インバウンドオプション**: `original_text` localeが必要

### 3. 競合店舗・競合分析

| 用途 | ファイル |
|------|---------|
| 競合モデル | `app/models/competitor.rb`, `app/models/store/competitor.rb` |
| 競合フォーム | `app/forms/biz/companies/location/competitor_form.rb` |
| 競合CSV | `app/models/import/distributor/csv/store_competitor.rb` |
| 星の数分析 | `app/models/analysis/review/aggregate.rb` |
| 競合相関分析 | `app/models/analysis/scatter/review/competitor_aggregate.rb`, `competitor_search.rb` |

データモデル:
- `competitors.store_id` は **ignored_columns**（旧1対1設計の名残）
- 中間テーブル `store_competitors` で N:N
- 販売店ごとの上限: `company_stocks.max_competitor_count`（default: 1）

### 4. 投稿・承認申請

```
app/usecases/biz/company/create_post_command.rb / update_post_command.rb
app/usecases/biz/company/create_drafted_post_command.rb / update_drafted_post_command.rb
app/usecases/biz/company/requesting_post/create_command.rb / update_command.rb / create_post_command.rb
app/forms/biz/post/validators.rb                  # all_stores_in_same_country など
app/forms/biz/drafted_post/validators.rb
```

### 5. Facebook連携

- 過去PR: #15430 (認証情報エラーメール), #15517 (再認証動線), #18074 (sentry通知を止める), #19138 (エラーハンドリング)
- **認証エラーはユーザーが自己解決できる動線**を優先（自動リトライしない）
- Sentryノイズが多いエラー種別は、動線整備後に通知を止める判断パターンがある

### 6. デモデータ — yaml駆動 + Builder群

```
config/settings/demo.yml                           # OEM(kcom/localone)×業種(food/retail/hotel/salon)×プラン(small/lite/basic) のオプション定義
lib/demo/{food,hotel,retail,salon}_company_factory.rb  # 業種別データ生成の司令塔
lib/demo/*_builder.rb                              # 口コミ/写真/投稿/GMBインサイト/検索キーワード等の約20個のBuilder
lib/tasks/demo.rake                                # demo:import タスク
lib/tasks/assets/                                  # GMBカテゴリJSON, 口コミCSV等の静的アセット
app/usecases/import_demo_company_usecase.rb       # 一括インポート（active_record-import でbulk insert）
```

**rake task**:
- `demo:import` ... DeleteDemoUsecase → ImportDemoUsecase → ImportLocaloneDemoUsecase の順
- `db:balus` の中でも呼ばれる

### 7. AIエージェントAPI — biz と完全分離

```
config/routes/ai_agent.rb                          # サブドメイン ai-agent (内部ALB) と ai-agent-external (n8n用外部ALB)
app/controllers/ai_agent/                          # Controller 配置場所（bizとは別ツリー）
app/models/company/ai_agent/                       # 集計ロジック（ActiveRecordではなくPOROベース）
config/settings/accessible_apis.yml                # API単位のアクセス制御
```

**主要API**:

| API | Controller | Model |
|-----|-----------|-------|
| 店舗ページアクセス分析 | `ai_agent/companies/analysis/visitors_controller.rb` | `Company::AiAgent::Analysis::Visitor` |
| 口コミ分析(CS会議) | `ai_agent/companies/analysis/reviews_controller.rb` | `Company::AiAgent::Analysis::Review` |
| MVP運用状況 | `ai_agent/companies/analysis/operational_statuses_controller.rb` | `Company::AiAgent::Analysis::OperationalStatus` |
| 注目キーワード | `ai_agent/companies/inbound_analysis/selected_keywords_controller.rb` | `Company::AiAgent::InboundAnalysis::SelectedKeyword` |
| 検索数内訳 | `ai_agent/companies/inbound_analysis/breakdown_search_keywords_controller.rb` | `Company::AiAgent::InboundAnalysis::BreakdownKeyword` |

---

## Key Knowledge（ハマりポイント集）

### GBP海外対応

詳細は **[docs/gmb/overseas.md #ハマりポイント](https://github.com/movinc/kutikomi-com/blob/main/docs/gmb/overseas.md#ハマりポイント)** を参照。

**思い出すための見出しだけ**:
- `language_code` は住所同期と投稿で方針が逆（日本のみ vs 全国）
- `region_code` は `.upcase` で正規化必須
- `locality` はホワイトリストで 5 箇所判定（serializer含む）
- `zhtw`/`zhhk` は GBP API 仕様（`zh-TW`/`zh-HK`）に変換が必要
- prefecture翻訳はGBPのreturn表記と完全一致（Hawaii→HI #19722）

### Searches多言語

- `"original_text"` locale は Searches には送れない → `"ja"` に変換して投稿
- タイ語 (`"th"`) は Searches 未対応 → 現状 `next` でスキップ（TODOコメントあり）
- **異国店舗の混在禁止**（#19404）: `Biz::Post::Validators` と `Biz::DraftedPost::Validators` の **両方**に
  `all_stores_in_same_country` を入れる。片方だけ入れると抜ける

### 競合分析の重複排除（過去2回バグ発生）

- `#16504`: `count(DISTINCT ...)` → `count(*)` + `.distinct`
- `#16920`: `sum(reviews.rating)` が重複レビューを含み、平均スコアが高く算出
  - `rated_post_count` は DISTINCT なのに `sum_rating` だけDISTINCTしていなかった
- **教訓**: 分析クエリは **常に `.distinct` を疑え**。countだけでなく `sum` にも適用が必要

### 競合店舗の重複登録

- 同名・同ブランドの `Competitor` は **再利用**（`CompetitorForm#set_existed_same_competitor`）
- `store_competitors` に `(store_id, competitor_id)` のUNIQUE制約
- CSV洗い替えは **既存紐付け全削除 → 新規作成** 方式（部分更新しない）

### デモデータ

- **ESインポートはメインのES importを待たない**: `ImportDemoCompanyUsecase` 内で
  `Biz::Company::Review::ImportFromCompanyCommand` / `CustomSurvey::StoreAnswer::ImportFromCompanyCommand` を直接呼ぶ（#13380）
- **翻訳APIはデモ店舗も通す**: `biz/api/base_controller.rb` で許可（#12632）
- **口コミ数はコスパ重視**: 最初は5000件超あったが、ESコスト/インポート時間の兼ね合いで 約600件に削減（#12778）
- **ECSメモリ**: `demo:import` はメモリを食うので `.github/workflows/deploy-batches.yml` で `task-mem-limit` を調整した実績あり（#12670）
- **業種×プラン×OEMの3次元マトリックス**で挙動が変わる → 触るときは `demo.yml` で該当軸を先に確認

### AIエージェントAPI

- **認証方式がbizと違う**: JWT + Client Credential の二重検証（`X-ACCESS-TOKEN` + `X-CLIENT-CREDENTIAL`）。Deviseセッションは使わない
- **クライアント**: mastra（社内AIエージェント）と n8n。外部ALB経由のn8n呼び出しもある
- **Controllerは薄く保つ**: ロジックは `Company::AiAgent::Analysis::*` / `Company::AiAgent::InboundAnalysis::*` のPOROに集約
- **設計の癖**: 全APIが `resource :xxx, only: [:show]` のGET単一リソース（index/createでなくshow）
- **BigQueryのSQLをRailsで再実装**するパターンあり（#18329）

---

## Common Workflows（定型手順）

### ワークフロー①: GBP連携に新しい国を追加する

**[docs/gmb/overseas.md #新国追加ワークフロー](https://github.com/movinc/kutikomi-com/blob/main/docs/gmb/overseas.md#新国追加ワークフロー)** 参照（5ステップの詳細、設計思想、対応PR）。

### ワークフロー②: 分析系クエリを書く/触る

1. 関連テーブルが **N:N を経由するか** を確認（store ↔ competitor の store_competitors など）
2. `count` だけでなく `sum`, `avg` にも **DISTINCTが要るか** を毎回確認
3. 集計単位（店舗単位/会社単位/期間単位）を明示してテストに落とす
4. `Analysis::Review::Aggregate` のテスト（特に `concerning :Competitor`）を参考にする

### ワークフロー③: CSVインポート機能を触る

1. `Import::Distributor::Csv::*` のクラスを確認
2. **トランザクション内で全行処理** し、1行でもエラーなら `InvalidCsv` raise で全ロールバック（**部分インポートしない**）
3. エラー時のSentry通知方針を確認（#16917, #17485 で過去に調整あり）

### ワークフロー④: デモデータを追加・修正する

1. `config/settings/demo.yml` で 業種×プラン×OEM のどの軸に属するか確認
2. データ生成は `lib/demo/<業種>_company_factory.rb` 経由
3. 新しいデータ種別なら `lib/demo/<something>_builder.rb` を追加
4. **ES反映を忘れない**: `ImportDemoCompanyUsecase` の `Review::ImportFromCompanyCommand` を確認
5. ローカルで `bin/rails demo:import` or `bin/rails db:balus` で動作確認
6. メモリを大きく使う追加をした場合は `.github/workflows/deploy-batches.yml` の `task-mem-limit` も確認

### ワークフロー⑤: AIエージェントAPIを追加する

1. 仕様（mastra/n8n側の期待するレスポンス）を確認
2. `config/routes/ai_agent.rb` にルート追加（`resource :xxx, only: [:show]` パターン）
3. `app/controllers/ai_agent/companies/<domain>/<name>_controller.rb` を作成（**薄く**）
4. 集計ロジックは `app/models/company/ai_agent/<domain>/<name>.rb` に POROで配置
5. `config/settings/accessible_apis.yml` にAPI登録
6. `User::ApiPermissions` のロール権限とプラン制御（`ProvidedFeature`）を確認
7. テスト: request specで JWT + ClientCredential の認証込みで書く

### ワークフロー⑥: Facebook認証エラー対応

1. エラー種別を確認（Token期限切れ / 権限失効 / FB側の一時障害）
2. **ユーザーが自己解決できる動線**を優先。自動リトライはしない
3. 運用で大量のSentry通知が来る種類のエラーは、動線整備後にSentry通知を止める

---

## 判断パターン（過去PRから抽出した設計の癖）

- **設定駆動を好む**: YAMLに寄せる。`if country == "JP"` のようなハードコードを避ける
- **受注前先行対応**: 新国は受注可能性が出た時点で準備（例: #18774 韓国）
- **バリデーションは両方の箇所に置く**: 投稿と下書きの両方、承認申請経由も忘れない
- **CSV は洗い替え方式**: 差分更新でバグを生むより、一度全削除→再作成の方が堅実
- **分析系は distinct を徹底**: `count`/`sum` 両方
- **Controllerは薄く**: AIエージェントAPIでも徹底。ロジックはPOROに逃がす
- **デモは「本物っぽさ」を数より多様性で出す**: 5000件→600件の削減はその判断

---

## How to Use This Skill

### モード1: 対話相談

ユーザーが次のように相談してきたら、このSkillを参照して回答する:

- 「GBPの海外対応で新しい国を追加したい」
- 「競合分析の数字がおかしい」
- 「Searches多言語のところでlocaleの扱いが分からない」
- 「Facebook認証エラーが出ている」
- 「投稿で国混在を禁止したい」
- 「demo:import が落ちる / デモデータに項目追加したい」
- 「AIエージェント用APIを追加したい」

**回答の型**:
1. 該当領域の **ドメインマップ** でファイル位置を提示
2. 該当する **Key Knowledge / Pitfall** を挙げる
3. 必要なら **Workflow** の定型手順を適用
4. 関連するPR番号を参照として示す（`movinc/kutikomi-com#18731` 形式）

### モード2: コード変更前のレビュー

上記7ドメインに該当するファイルを触るPRのレビュー時、以下をチェック:

- [ ] `country_to_locale_mapping.yml` に新国追加なら全5ステップ踏んだか
- [ ] 分析系クエリに `.distinct` が入っているか（count/sumの両方）
- [ ] 投稿系バリデーションが `Post` と `DraftedPost` の両方に入っているか
- [ ] GBP API送信で `language_code` を国別で正しく制御しているか
- [ ] CSVインポートがトランザクション+全ロールバック方式か
- [ ] AIエージェントAPIは `resource :show` パターンでControllerが薄いか
- [ ] デモデータ変更でESインポート経路に漏れがないか

### モード3: 新人オンボーディング

該当ドメインに初めて触る開発者には、このSkillの「ドメインマップ」と「Key Knowledge」を先に共有する。
代表PR（表の一番右）を1つずつ読むと、設計判断の流れが理解できる。

---

## 参考PR一覧（領域別）

### GBP海外対応
**[docs/gmb/overseas.md #参考PR](https://github.com/movinc/kutikomi-com/blob/main/docs/gmb/overseas.md#参考pr)** 参照（11件）。

### Searches多言語
- movinc/kutikomi-com#13257 投稿APIにてSearches多言語投稿データを作成できるようにする
- movinc/kutikomi-com#13275 下書き投稿Searches多言語対応
- movinc/kutikomi-com#13298 searches多言語の場合もlocaleを返すように
- movinc/kutikomi-com#13309 投稿承認申請APISearches多言語対応
- movinc/kutikomi-com#19220 【BE】原文localeにて投稿を行えるようにする
- movinc/kutikomi-com#19332 店舗絞り込みモーダルにて国での絞り込みを行えるように
- movinc/kutikomi-com#19404 投稿APIに異なる国の店舗を複数選択できないように

### 競合分析
- movinc/kutikomi-com#15736 競合店舗を複数設定できるようにする
- movinc/kutikomi-com#16088 重複競合店舗を登録できるように
- movinc/kutikomi-com#16264 競合店舗の重複登録を可能にする
- movinc/kutikomi-com#16779 競合店舗紐付けCSV機能追加
- movinc/kutikomi-com#16481 競合相関分析API追加
- movinc/kutikomi-com#16504 星の数分析の累計口コミ件数が実際の値と違う問題修正
- movinc/kutikomi-com#16920 口コミ評価重複問題対応

### 投稿機能
- movinc/kutikomi-com#15620 投稿で検索ワード検索ができるように
- movinc/kutikomi-com#15671 繰り返し投稿絞り込み機能追加
- movinc/kutikomi-com#17135 公開終了予定日カラムをPostに追加
- movinc/kutikomi-com#17150 公開終了予定日のAPI対応
- movinc/kutikomi-com#17187 公開終了日を過ぎた投稿をcloseするバッチ追加

### Facebook連携
- movinc/kutikomi-com#15393 Facebookアカウント名を保存する
- movinc/kutikomi-com#15430 Facebook認証情報エラーメール追加
- movinc/kutikomi-com#15517 Facebookアカウント再認証動線追加
- movinc/kutikomi-com#18074 facebook認証エラーのsentry通知を止める
- movinc/kutikomi-com#19138 FacebookAPIエラーハンドリング

### デモデータ
- movinc/kutikomi-com#12651 デモ店舗の各店舗オプション管理をyamlで行う
- movinc/kutikomi-com#12670 demo importのメモリをあげる
- movinc/kutikomi-com#12699 外国語アンケートフォームを追加
- movinc/kutikomi-com#12778 デモ店舗の口コミ数を減らす
- movinc/kutikomi-com#12623 ホテルdemo店舗にOTA口コミ追加
- movinc/kutikomi-com#12632 デモ店舗でも翻訳APIが正常に動作するようにする
- movinc/kutikomi-com#13380 デモ店舗のESインポートをdemo:import taskで行うようにする
- movinc/kutikomi-com#16755 デモデータに承認口コミデータ追加

### AIエージェントAPI
- movinc/kutikomi-com#18228 AIエージェント: 店舗ページアクセス分析用API追加
- movinc/kutikomi-com#18329 CS会議準備ダッシュボード-口コミのAPI追加
- movinc/kutikomi-com#18504 社内向けAIエージェント - インバウンド分析 - 検索数 - 注目キーワードのAPI追加
- movinc/kutikomi-com#18537 検索数内訳API追加
- movinc/kutikomi-com#19047 MVPダッシュボード用API追加
- movinc/kutikomi-com#18002 競合データ重複解消

---

## Skillの更新方法

1. **新しい関連PRの取得**:
   ```bash
   gh pr list --search "<領域キーワード> in:title" --state merged --limit 20
   ```
2. **知識の追記**: 該当領域の「Key Knowledge」に追記。PR番号をリンク化
3. **設定ファイルの最新化**: `config/settings/*.yml` に新しい国が増えたら Domain Map を更新
4. **誤りの訂正**: 実装が変わった箇所は **更新日付付きで上書き** する

本Skillは「凍結されたドキュメント」ではなく「育てるドキュメント」として扱ってください。

将来チーム展開する場合は、このSkillを `~/.claude/skills/` から `kutikomi-com/.claude/skills/` に移動すると
リポジトリ利用者全員で共有できます。

---

## Notes / 制約

- 本Skillは関連PRとコメントから推論した内容であり、設計時の意図と完全一致するとは限らない
- 実装は日々変わるため、**Skillの記述と現コードが食い違う場合は現コードを信じる**（そしてSkillを更新する）
