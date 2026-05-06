---
name: flamingo-retro-sync
description: |
  Google Docsに生成されたFlamingoチームのレトロスペクティブ議事録を取得し、
  Obsidian vaultへ保存してgit commitする。Gemini文字起こしの典型的な誤認を補正する。
  トリガー: "/flamingo-retro-sync [<日付>] [<Google DocsのURL>]"
  使用場面: Flamingoチームレトロ実施後に議事録をObsidianへ保存するとき。
  「Flamingoレトロ保存して」「レトロ議事録同期」「チームレトロ格納」などの発言でも使用する。
  flamingo-retroスキル（週次ふりかえり資料生成）とは別物。
  こちらは**レトロ会議の議事録そのもの**を保存する。
---

# Flamingo Retro Sync

Google Docsに生成されたFlamingoチームレトロスペクティブの議事録を取得し、Obsidian vaultに整形保存してgit commitする。

## 引数

`$ARGUMENTS` は **日付・URLどちらも省略可能** で、順序も問わない。以下のいずれのパターンも受け付ける:

- **URLのみ**（推奨 / 最短）: `/flamingo-retro-sync https://docs.google.com/document/d/XXXXX/edit`
  → 議事録冒頭のGemini生成日付（例: `4月 15, 2026`）から日付を自動抽出
- **日付 + URL**: `/flamingo-retro-sync 2026-04-15 https://docs.google.com/document/d/XXXXX/edit`
  → URLをダウンロードし、引数の日付を優先して使用（議事録の日付と不一致の場合はユーザーに確認）
- **日付のみ**: `/flamingo-retro-sync today` / `/flamingo-retro-sync 2026-04-15`
  → URLを対話で取得
- **引数なし**: `/flamingo-retro-sync`
  → URL・日付を対話で取得（まずURLを聞き、日付は議事録から抽出を試みる）

日付の形式:
- `YYYY-MM-DD`（例: `2026-04-15`）
- `today` / `yesterday`（日本時間JSTで解釈）
- 省略時は議事録冒頭から抽出（下記「日付の自動抽出」を参照）

URLの形式:
- `https://docs.google.com/document/d/{DOC_ID}/edit...`
- ドキュメントIDを直接渡しても可

## 定数

- **Googleアカウント**: `y.minamiya@mov.am`
- **Obsidian vault**: `/Users/minamiyayuki/src/github.com/yuki3738/obsidian-vault`
- **保存先**: `Work/mov/Flamingo/retro/YYYY-MM-DD.md`

## Flamingoメンバー（議事録内の表記ゆれ補正に使用）

| 正規表記 | Gemini誤認の例 |
|---|---|
| 藤牧宗太郎 | 藤巻、ふじまき、藤牧そうたろう |
| 加藤裕太 | 加藤ゆうた、かとう |
| 藤田泰輔（yodaka） | よだか、ヨダカ、夜鷹、yodakaEngineer、藤田 |
| 川口将吾 | 川口しょうご、k-shogo、川口翔吾 |
| 大垣祐介 | 大垣ゆうすけ、おおがき、yusuke-ogaki |
| 山本純己（愛称: カシマさん / GitHub: mtkasima） | 山本すみおき、やまもと、山本順己、鹿島、カシマ、島、kasima、mtkashima |
| 南谷祐貴 | 南谷ゆうき、みなみや、minamiya |

※ メンバーは時期によって増減する。不明な人名が出たら勝手に修正せず、ユーザーに確認する。

## 手順

### Phase 0: 引数の解析

1. `$ARGUMENTS` を空白で分割し、各トークンを以下のルールで分類する:
   - `docs.google.com/document/d/` を含む or 32文字以上の英数字+ハイフン+アンダースコア文字列 → **URL/ドキュメントID**
   - `today` / `yesterday` / `YYYY-MM-DD` 形式 → **日付**
2. URLが無ければユーザーに入力を求める
3. URLからドキュメントID (`$DOC_ID`) を抽出する
   - URL形式の場合: `https://docs.google.com/document/d/{DOC_ID}/edit...` から正規表現で抽出
   - IDのみの場合: そのまま使用
4. 日付が引数で指定された場合はそれを仮の `$DATE` とする。未指定なら Phase 2 で議事録から抽出する

#### 日付の自動抽出（引数で日付が未指定のとき）

議事録のダウンロード後、冒頭2〜5行目あたりにGeminiが生成した日付が含まれる。以下のフォーマットに対応する:

- `4月 15, 2026` / `4月15日, 2026年` / `2026年4月15日` → `2026-04-15`
- 英語: `April 15, 2026` / `Apr 15, 2026` → `2026-04-15`

抽出に失敗した場合は**今日の日付（JST）**をデフォルトとし、ユーザーに「日付を抽出できなかったので `YYYY-MM-DD` でよいか」確認する。

#### 引数で日付が指定されていて、議事録の日付と一致しないとき

ユーザーに両方の日付を提示して、どちらを採用するか確認する。誤ったdocument IDを渡されている可能性もあるので勝手に進めない。

### Phase 1: Google Docsからダウンロード

日付未確定でも先にダウンロードする（出力ファイル名は `$DOC_ID` ベース）。`gws` の Markdown export を使うと見出し・太字・リンクが構造化されたまま取れる:

```bash
# gws の --output は cwd 配下にしか書けないため /tmp に cd する
cd /tmp && gws drive files export --params '{
  "fileId": "$DOC_ID",
  "mimeType": "text/markdown"
}' --output flamingo-retro-$DOC_ID.md
```

失敗した場合:
- **OAuth token期限切れ** (`invalid_grant`): ユーザーに `gws auth login` の実行を依頼
- **スコープ不足**: `gws auth login --services drive,docs` を依頼
- **ファイル未発見**: URLが正しいかユーザーに確認

### Phase 2: 日付の確定とコンテンツの整形

ダウンロードしたtxtを以下の方針で処理する。

#### 2-0. 日付の確定

1. **引数で日付が指定されていれば** → その日付を `$DATE` として採用
2. **引数で未指定** → ファイルの先頭20行から日付を抽出:
   - 正規表現: `(\d+)月\s*(\d+)[,，、]?\s*(\d{4})` / `(\d{4})年(\d+)月(\d+)日` / `(January|February|...|Dec(?:ember)?)\s+(\d+),?\s+(\d{4})`
   - 抽出成功 → `YYYY-MM-DD` 形式に正規化して `$DATE` として採用
   - 抽出失敗 → 今日の日付（JST）をデフォルト提示し、ユーザーに `YYYY-MM-DD` でよいか確認
3. **引数指定の日付と議事録の日付が不一致** → 両方を提示して確認（誤ったDocumentIDの可能性もあるため勝手に進めない）

確定した `$DATE` は以降の保存先・commitメッセージ・frontmatterに使用する。

#### 2-1. Geminiヘッダー・フッターの除去

- 冒頭の `📝 メモ` / 日付行 / `招待済み ...` / `添付ファイル ...` は除去する
  - ただし**招待済みのメンバーはfrontmatterの `attendees` に転記**する
- 末尾の `この要約を評価する...` / `Gemini が生成したメモの内容...` / フィードバック案内は除去する

#### 2-2. Gemini誤認の補正

以下は**機械的に置換**する（明らかな誤認が定着している表現）:

| 誤 | 正 |
|---|---|
| アプルブ | アプルーブ |
| プルリク | プルリクエスト（文脈次第。短縮形のままで自然な箇所は残す） |
| クロード | Claude |

以下は**文脈判断で補正**（自動置換はしない、判断して補正する）:

- 技術用語の片仮名化ミス: `マスタラ` → `Mastra` / `ノーション` → `Notion` / `ギットハブ` → `GitHub` / `スラック` → `Slack` など、AIエージェント・開発ツール文脈で明らかに英語名が正しいもの
- 人物名: 上記メンバーリストに従って正規表記に揃える
- プロジェクト名・チーム名: `フラミンゴ` / `Framingo` → `Flamingo`

**判断に迷うものは原文のまま残し、最後の完了報告に `[要確認] 不明な表現: XXX` として列挙する**。勝手に推測で書き換えない。

#### 2-3. 構造化

- `概要` / `次のステップ` / `詳細` をそれぞれ `## 概要` / `## 次のステップ` / `## 詳細` に変換
- 概要内のサブ見出しは `###` に
- 箇条書きの `*` を `-` に統一
- `[担当者] アクション名: 説明` 形式は `**[担当者]** アクション名: 説明` に整形
- 太字の固有名詞・トピックタイトル（`XXXの検討:` など）は `**XXX**:` に統一

#### 2-4. frontmatterの付与

`attendees` は **本名 / GitHub login / 愛称** を三位一体で記録する（愛称は任意）。メンバー表の正規表記と照合して埋める。

```yaml
---
date: YYYY-MM-DD
type: team-retro
team: Flamingo
attendees:
  - name: 山本純己
    github: mtkasima
    alias: カシマさん
  - name: 大垣祐介
    github: yusuke-ogaki
  - name: 藤田泰輔
    github: yodakaEngineer
    alias: yodaka
  - name: 川口将吾
    github: k-shogo
  - name: 加藤裕太
    github: YutaKato3548
  - name: 南谷祐貴
    github: yuki3738
  - name: 藤牧宗太郎
    github: sotarofujimaki
tags:
  - flamingo
  - retro
---
```

**メンバーが変わったら**: 本skillの「Flamingoメンバー」表と合わせて、`brain/Memories.md` の `## People` セクションも更新する。誰の代わりに誰が入ったかの履歴も残す。

#### 2-5. 本文の先頭に見出し追加

```markdown
# Flamingoチームレトロスペクティブ YYYY-MM-DD
```

#### 2-6. 関連リンクセクションの追加

本文末尾に:

```markdown
## 関連

- 週次ふりかえり: [[flamingo-retro-YYYY-MM-DD|Flamingo 週次ふりかえり]]
```

※ `Private/Weekly/YYYY/MM/flamingo-retro-YYYY-MM-DD.md` が既に存在する場合のみリンクを書く。存在しなければこのセクションを省略。

### Phase 3: 保存

保存先: `Work/mov/Flamingo/retro/YYYY-MM-DD.md`

- ディレクトリが存在しない場合は作成する
- 同名ファイルが既に存在する場合は**上書き前にユーザーに確認**する

### Phase 4: Git commit

```bash
cd /Users/minamiyayuki/src/github.com/yuki3738/obsidian-vault
git add "Work/mov/Flamingo/retro/YYYY-MM-DD.md"
git commit -m "docs: add Flamingo retro YYYY-MM-DD"
```

push はしない（ユーザーに任せる）。

### Phase 5: 完了報告

以下を出力する:

- 保存先ファイルパス
- 元のGoogle Docsドキュメント名
- 出席者リスト
- 次のステップ（アクションアイテム）の一覧
- `[要確認]` でフラグした不明な表現（あれば）

## 注意事項

- Google Docsから議事録が取れない場合は、必ずユーザーに確認する（勝手に処理を中断しない）
- メンバーリストにない人名が登場した場合、**Flamingoメンバーが変わった可能性**があるので、ユーザーに確認する
- 不明な単語を推測で書き換えない。原文のまま残して `[要確認]` リストに入れる
- `flamingo-retro` スキル（週次ふりかえり資料生成）とは別物なので混同しない
