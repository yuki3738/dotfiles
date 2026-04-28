---
name: 1on1-sync
description: |
  Google Docsの1on1議事録をObsidianに取り込みgit commitする。
  トリガー: "/1on1-sync <名前> <日付>"
  使用場面: 1on1実施後に議事録をObsidianへ保存
---

# 1on1 Sync

Google Docsに生成された1on1議事録を取得し、Obsidian vaultへ保存してgit commitする。

## 引数

$ARGUMENTS を以下のように解釈する:

- 形式: `<名前> <日付>`（例: `Yamamoto 2025-11-27`、`Miyachi today`）
- 名前: チームメンバーの名前（部分一致でマッチング可）
- 日付: `YYYY-MM-DD` 形式、`today`、`yesterday` のいずれか

## 定数

- **Googleアカウント**: `y.minamiya@mov.am`
- **Obsidian vault**: `/Users/minamiyayuki/src/github.com/yuki3738/obsidian-vault`
- **1on1保存先**: `Work/mov/1on1/[名前ディレクトリ]/YYYY-MM-DD.md`

## 手順

### Phase 0: 引数の解析

1. `$ARGUMENTS` から**名前**と**日付**を分離する
2. 日付を日本時間(JST)として解釈する
   - `today` → 本日の日付
   - `yesterday` → 昨日の日付
   - それ以外 → `YYYY-MM-DD` としてパース

### Phase 1: 名前の解決

既存の1on1ディレクトリ一覧から名前をマッチさせる。

```bash
ls "/Users/minamiyayuki/src/github.com/yuki3738/obsidian-vault/Work/mov/1on1/"
```

マッチングルール:
- **完全一致**: 入力が既存ディレクトリ名と完全一致
- **部分一致**: 入力がディレクトリ名の一部に含まれる（大文字小文字不問）
- **複数マッチ**: 候補をユーザーに提示して選択してもらう
- **マッチなし**: ユーザーに正しい名前を確認する。新規メンバーの場合はディレクトリを新規作成する

解決後の名前を `$MEMBER_NAME` とする。

### Phase 2: Google Docsの検索

`gws` CLIを使ってGoogle Driveから1on1議事録を検索する（Geminiメモはタイトルに名前が入らないため `fullText contains` を使う）。

#### Step 2-1: ドライブ検索

以下の検索を順番に試行し、**最初にヒットした結果**を使用する:

```bash
# 検索1: 名前 + "1on1" で本文検索
gws drive files list --params '{
  "q": "fullText contains '\''$MEMBER_NAME 1on1'\'' and mimeType='\''application/vnd.google-apps.document'\'' and trashed=false",
  "pageSize": 10,
  "fields": "files(id,name,mimeType,modifiedTime,webViewLink)",
  "orderBy": "modifiedTime desc"
}'

# 検索2: 名前のみで本文検索
gws drive files list --params '{
  "q": "fullText contains '\''$MEMBER_NAME'\'' and mimeType='\''application/vnd.google-apps.document'\'' and trashed=false",
  "pageSize": 10,
  "fields": "files(id,name,mimeType,modifiedTime,webViewLink)",
  "orderBy": "modifiedTime desc"
}'
```

検索結果のJSONから以下の条件でフィルタリングする:
- `mimeType` が `application/vnd.google-apps.document`（Google Docs）であること
- 指定日付に近い `modifiedTime` であること
- 必要に応じてファイル名に名前や "1on1" が含まれることを優先

#### Step 2-2: 候補の絞り込み

- **1件のみ**: そのドキュメントを使用
- **複数候補**: ファイル名の一覧をユーザーに提示し、選択してもらう
- **0件**: ユーザーにGoogle DocsのURLまたはドキュメントIDを直接入力してもらう

該当ドキュメントの `id` を `$DOC_ID` とする。

### Phase 3: 議事録コンテンツの取得

`gws drive files export` で **Markdown** としてダウンロードする（見出し・太字・リンクが構造化されて保持される）:

```bash
# gws の --output は cwd 配下にしか書き込めないため、/tmp に cd してから実行する
cd /tmp && gws drive files export --params '{
  "fileId": "$DOC_ID",
  "mimeType": "text/markdown"
}' --output 1on1-$MEMBER_NAME-YYYY-MM-DD.md
```

ダウンロードしたファイルの内容を `$CONTENT` とする。

#### コンテンツの検証

- コンテンツが空、または極端に短い（数文字程度）場合はユーザーに確認する
- 指定日付の1on1に関連する内容かどうかを簡易チェックする（日付が含まれているか等）
  - 明らかに異なる内容の場合、ユーザーに確認する

### Phase 4: Markdownファイルの作成

`gws` の Markdown export は見出し（`#`/`##`/`###`）・太字（`**`）・リンク（`[text](url)`）・箇条書き（`*`）が既に構造化されている。以下の整形のみ行う:

- Gemini生成メモのヘッダー部分（「📝 メモ」「日付」「招待済み...」「添付ファイル...」）は除去する
- Gemini生成メモのフッター部分（「Gemini が生成したメモの内容の正確性をご確認ください。」以降）は除去する
- 「この要約を評価する」など Gemini フィードバックリンクの行は除去する
- `*` 箇条書きを `-` に統一する（必要に応じて）
- ローマ字の人名はGoogle Docsに記載されているものをそのまま使用する（漢字の表記が必要な場合のみユーザーに確認）
- 会社名「Mob」「モブ」は **mov**（株式会社mov）に置換する

保存先パス:
```
/Users/minamiyayuki/src/github.com/yuki3738/obsidian-vault/Work/mov/1on1/$MEMBER_NAME/YYYY-MM-DD.md
```

- ディレクトリが存在しない場合は作成する
- 同名ファイルが既に存在する場合は**上書き前にユーザーに確認**する

### Phase 5: Git commit & push

```bash
cd /Users/minamiyayuki/src/github.com/yuki3738/obsidian-vault
git add "Work/mov/1on1/$MEMBER_NAME/YYYY-MM-DD.md"
git commit -m "docs: add 1on1 notes $MEMBER_NAME YYYY-MM-DD"
git push
```

### Phase 6: 完了報告

以下の情報を出力する:
- 保存先ファイルパス
- 元のGoogle Docsドキュメント名
- コンテンツのプレビュー（最初の数行）

## 注意事項

- Google Docsから議事録が見つからない場合は、必ずユーザーに確認する（勝手に処理を中断しない）
- ユーザーがドキュメントのURLを提供した場合、URLからドキュメントIDを抽出する
  - 形式: `https://docs.google.com/document/d/{DOC_ID}/edit`
- `gws` コマンドが失敗した場合はエラー内容をユーザーに伝え、対処法を提案する
  - 認証期限切れ（`invalid_grant` / `Token has been expired`）: ユーザーに `gws auth login` の実行を依頼する
  - スコープ不足: `gws auth login --services drive,docs` を依頼する
