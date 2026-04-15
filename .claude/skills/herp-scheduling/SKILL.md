---
name: herp-scheduling
description: HERP Hire APIを使って候補者にコンタクトを作成し、日程調整URLを生成する。「日程調整」「HERP」「面談設定」「コンタクト作成」などの発言で使用する。
argument-hint: <候補者名 or 応募ID>
---

# HERP 日程調整URL生成

## あなたの役割

HERP Hire APIを使用して、候補者へのコンタクト作成と日程調整URLの生成を行う。

## 環境変数

- `HERP_API_KEY`: HERP Hire APIキー（必須、`~/.env` に設定 → `.zshrc` で `source ~/.env` 経由で自動ロード）

## 前提知識: HERP Hire API

- ベースURL: `https://public-api.herp.cloud/hire`
- 認証: `Authorization: Bearer {HERP_API_KEY}`
- レート制限: テナントあたり1分間100リクエスト
- スクリプト: `~/.claude/skills/herp-scheduling/herp_create_scheduling.rb`

### エンドポイント

| メソッド | パス | 用途 |
|---------|------|------|
| GET | /v1/users | ユーザー一覧取得 |
| GET | /v1/candidacies | 応募一覧取得 |
| GET | /v1/candidacies/{id} | 応募詳細取得 |
| POST | /v1/candidacies/{id}/contacts | コンタクト作成（日程調整URL生成） |

### コンタクトタイプ

- `interview`: 面接
- `meeting`: 面談（カジュアル面談等）
- `document`: 書類選考
- `aptitudeTest`: 適性検査
- `referenceCheck`: リファレンスチェック
- `offerInterview`: オファー面談

### 選考ステップ

- `entry`: エントリー
- `casualInterview`: カジュアル面談
- `resumeScreening`: 書類選考
- `firstInterview`: 一次面接
- `secondInterview`: 二次面接
- `thirdInterview`: 三次面接
- `finalInterview`: 最終面接
- `offered`: 内定
- `offerAccepted`: 内定承諾

### assessmentSchedule の type

- `register`: 予定確定で作成（日時確定、URLは返らない）
- `suggestTimeSlots`: 候補日程を提案（複数の候補から候補者に選んでもらう）
- `shareFreeTimeSlots`: 空き時間を共有（日程調整URLを生成、候補者にスロットから選ばせる） ← **カジュアル面談の定番**

`shareFreeTimeSlots` の必須フィールド:
- `type`, `adjustBy`, `title`, `attendeeIds`, `adjustmentMethod`（`all` or `partial`）

### POST /v1/candidacies/{id}/contacts レスポンス

```json
{
  "contactId": "string",
  "assessmentScheduleId": "string",
  "appointmentSchedulingUrl": "string",  // 日程調整URL（shareFreeTimeSlots/suggestTimeSlotsで返却）
  "googleMeetingUrl": "string",          // Google Meet URL（該当時のみ）
  "evaluationRequestIds": ["string"],
  "errors": [{"message": "string"}]
}
```

## 実行ステップ

### Step 1: 環境確認

`HERP_API_KEY` が設定されていることを確認する。未設定の場合は `~/.env` に `export HERP_API_KEY=...` を追加するよう案内する（`~/.zshrc` で `source ~/.env` により自動ロードされる）。

### Step 2: 情報収集

ユーザーから提供された情報に応じて必要な情報を収集する。

1. **応募IDが不明な場合**: 候補者名で検索する
   ```bash
   ruby ~/.claude/skills/herp-scheduling/herp_create_scheduling.rb --search "候補者名"
   ```

2. **ユーザーIDが不明な場合**: ユーザー一覧を取得する
   ```bash
   ruby ~/.claude/skills/herp-scheduling/herp_create_scheduling.rb --list-users
   ```

3. **応募の現在のステータスを確認**:
   ```bash
   ruby ~/.claude/skills/herp-scheduling/herp_create_scheduling.rb --get-candidacy CANDIDACY_ID
   ```

### Step 3: ユーザーに確認

以下をユーザーに確認する（不明な場合のみ）:

- **コンタクトタイプ**: カジュアル面談なら `meeting`、選考面接なら `interview`
- **選考ステップ**: 現在のステップ（例: `casualInterview`）
- **面談タイトル**: 例: 「カジュアル面談」「一次面接」
- **参加者**: 面談に参加するメンバーのユーザーID
- **日程**: 開始・終了時間（予定作成する場合）
- **カレンダー**: iCal or Googleカレンダー（Googleカレンダーの場合、Meet URL自動生成の有無）

### Step 4: コンタクト作成

スクリプトを実行してコンタクトを作成する。

**カジュアル面談 + 日程調整URL生成（最頻ケース）**:
```bash
ruby ~/.claude/skills/herp-scheduling/herp_create_scheduling.rb \
  --candidacy-id CANDIDACY_ID \
  --create-by USER_ID \
  --contact-type meeting \
  --step casualInterview \
  --share-free-time-slots \
  --title "カジュアル面談" \
  --attendee-ids USER_ID
```
→ レスポンスの `appointmentSchedulingUrl` が日程調整URL

**面接の予定付きコンタクト作成例**:
```bash
ruby ~/.claude/skills/herp-scheduling/herp_create_scheduling.rb \
  --candidacy-id CANDIDACY_ID \
  --create-by USER_ID \
  --contact-type interview \
  --step firstInterview \
  --title "一次面接" \
  --starts-at "2026-04-15T14:00:00+09:00" \
  --ends-at "2026-04-15T15:00:00+09:00" \
  --attendee-ids USER_ID1,USER_ID2 \
  --google-calendar \
  --create-meeting-url
```

### Step 5: 結果出力

APIレスポンスを整形して出力する:

- **contactId**: 作成されたコンタクトID
- **appointmentSchedulingUrl**: 日程調整URL（存在する場合）
- **googleMeetingUrl**: Google Meet URL（存在する場合）
- **errors**: エラーがあれば表示

### Step 6: 候補者送付メッセージの生成

ユーザーから依頼があれば、生成した日程調整URLを使って候補者に送るメッセージを作成する。

#### カジュアル面談の招待メッセージ・テンプレート

```
{候補者姓}様

はじめまして。株式会社movの南谷と申します。
この度はご応募いただきありがとうございます。

ぜひ一度カジュアル面談の機会をいただければと思い、ご連絡いたしました。
選考の場ではなく、弊社の事業やプロダクト、チームの雰囲気などをお伝えしつつ、
{候補者姓}様のご経験やご関心についてもお聞きできればと考えています。

下記URLから、ご都合の良いお時間をご選択ください。

{appointmentSchedulingUrl}

お会いできるのを楽しみにしております。
どうぞよろしくお願いいたします。

株式会社mov
南谷 祐貴
```

#### 文体ルール（候補者向けメッセージ）

**必ず守ること:**

- 「カジュアル面談」と「選考面接」を混同しない。カジュアル面談は「選考の場ではない」ことを明示する
- 「です・ます」調、丁寧なビジネス敬語
- 候補者の姓に「様」をつける（呼び捨て・「さん」は不可）
- 社名は「株式会社mov」（前株）
- 候補者プロフィールを未確認の場合、推測で経験や興味に言及しない
- 給与・年収・面談所要時間への言及は避ける（HERP/媒体側で別途案内されるため）

**禁止する表現パターン:**

- **「お時間」の重複**: 「ご都合の良いお時間をお選びいただけます」+「お時間いただけますと幸いです」のように同じ語が近接で重複する文をつなげない
- **受け身の弱い依頼**: 「お選びいただけます」（〜できます）で終わらせず、「ご選択ください」と能動的な依頼にして行動を促す
- **不要な定型句**: 「ご検討のほどよろしくお願いいたします」のような選考案内的な表現は、カジュアル面談の招待では使わない

**推奨するクロージング:**

- 「お会いできるのを楽しみにしております。どうぞよろしくお願いいたします。」
- 「ぜひ一度お話しできればと思います。よろしくお願いいたします。」

#### 出力先

メッセージはチャット出力後、ユーザーが `/copy` でクリップボードにコピーできる状態にする。

## エラー対応

| エラー | 対処 |
|-------|------|
| 401 認証エラー | `HERP_API_KEY` の値を確認 |
| 403 権限エラー | APIキー発行ユーザーの権限を確認 |
| 404 リソース未検出 | 応募IDが正しいか確認 |
| 422 バリデーションエラー | パラメータの値を確認（stepとtypeの組み合わせ等） |
| 429 レート制限 | 1分待ってからリトライ |

## 注意事項

- APIキーの権限スコープは `candidacy:write` 以上が必要
- `createBy` に指定するユーザーはアシスタント以上の権限が必要
- 日程調整URLはHERP側で日程調整が進行中の場合のみレスポンスに含まれる
