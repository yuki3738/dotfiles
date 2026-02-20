---
name: article-to-em-skill
description: |
  指定されたURLの記事を読み込み、EM向けのClaude Code Skillを生成する。
  トリガー: "/article-to-em-skill <ARTICLE_URL>"
  使用場面: 記事の知見をEM業務に活用できるSkillとして定着させたいとき
---

# Article to EM Claude Code Skill Generator

指定されたURLの記事を読み込み、Engineering Manager（EM）向けのClaude Code Skillを生成する。
ログインが必要なページにも対応し、ユーザーの手動ログイン後に処理を再開する。

## 引数

$ARGUMENTS を以下のように解釈する:

- 形式: `<ARTICLE_URL>`（例: `https://example.com/article/123`）
- ARTICLE_URL: 対象記事のURL

## 手順

### Step 1: 記事の取得

1. まず `WebFetch` で `$ARTICLE_URL` にアクセスし、記事の全文取得を試みる
2. WebFetchで十分なコンテンツが取得できない場合（ログイン壁、ペイウォール等）:
   a. `mcp__claude-in-chrome__tabs_create_mcp` で新規タブを開く
   b. `mcp__claude-in-chrome__navigate` で `$ARTICLE_URL` にアクセスする
   c. `mcp__claude-in-chrome__read_page` でページ内容を確認する
   d. ログインが必要と判断した場合は**即座に作業を停止**し、以下をユーザーに伝える:
      > ログインが必要なページです。ブラウザでログインを完了したら「完了」と入力してください。
   e. ユーザーから「完了」の入力を受け取ったら、再度 `mcp__claude-in-chrome__navigate` でアクセスし `mcp__claude-in-chrome__read_page` で記事を取得する
3. 取得した記事の全文を `$ARTICLE_CONTENT` とする
4. 記事のタイトルを `$ARTICLE_TITLE` とする

#### コンテンツの検証

- コンテンツが空、または極端に短い場合はユーザーに確認する
- 記事ではなくエラーページやトップページが取得された場合はユーザーに報告する

### Step 2: 分析・設計方針の提示

`$ARTICLE_CONTENT` を以下の観点で分析し、EMにとって有益な情報を抽出する。
結果を**箇条書き**でユーザーに提示し、確認（「OK」「進めて」など）を得てから次のステップへ進む。

#### 抽出観点

1. **チームマネジメントに活用できる知識・フレームワーク**
   - リーダーシップモデル、チームビルディング手法
   - コミュニケーション改善のためのフレームワーク
   - 心理的安全性やモチベーション理論

2. **1on1・評価・採用などの業務シナリオへの適用方法**
   - 1on1での活用方法（質問テンプレート、議題設計など）
   - 評価面談やフィードバックへの応用
   - 採用面接・オンボーディングへの活用

3. **技術戦略・意思決定に役立つベストプラクティス**
   - 技術選定、アーキテクチャ決定のフレームワーク
   - トレードオフ分析の方法
   - チームの技術力向上施策

#### 提示フォーマット

```
## 記事分析結果

**記事タイトル**: $ARTICLE_TITLE
**URL**: $ARTICLE_URL

### 抽出した知見
- [知見1の要約]
- [知見2の要約]
- ...

### 生成するSkillの方向性
- **Skill名案**: [提案]
- **主な用途**: [どんな場面で使うか]
- **対象シナリオ**: [具体的なEM業務シナリオ]

この方向性で SKILL.md を生成してよいですか？
```

### Step 3: SKILL.md の生成

ユーザーの確認を得たら、以下のテンプレートに沿って SKILL.md を生成する。

#### Skill名の決定

- **必ず `em-` プレフィックスを付ける**（他のSkillとの名前衝突を防ぐため）
- 記事の内容に基づき、`em-` + kebab-case で簡潔なSkill名を決定する
- 例: `em-situational-leadership`, `em-radical-candor-feedback`, `em-okr-coaching`
- 生成前に既存の `.claude/skills/` ディレクトリ一覧を確認し、重複がないことを検証する
- Skill名を `$SKILL_NAME` とする

#### 出力テンプレート

```markdown
---
name: $SKILL_NAME
description: |
  [Skillの概要（1-2行）]
  トリガー: "/$SKILL_NAME"
  使用場面: [主な使用場面]
---

# Skill: [Skill名（日本語）]

## Overview
[このSkillが何をするか・どんな場面で使うかの説明]

**出典**: [$ARTICLE_TITLE]($ARTICLE_URL)

## Target Scenarios
[対象となるEMの業務シナリオ一覧（箇条書き）]

## Key Knowledge
[記事から抽出した重要な知識・フレームワーク]

## Instructions
[Claude Codeへの具体的な指示内容。ユーザーの状況をヒアリングし、記事の知見に基づいてアドバイスやテンプレートを提供する手順]

## Usage Examples
[実際の使用例（最低3パターン）]

## Notes
[制約事項・注意点]
```

#### Instructions セクションの設計方針

- ユーザーの現在の状況や課題を**対話的にヒアリング**するステップを含める
- 記事の知見を**具体的なアクション**に落とし込む指示にする
- テンプレートやチェックリストなど**そのまま使える成果物**を出力する指示を含める
- 「一般論を述べる」だけでなく、ユーザーの具体的な文脈に適用する指示にする

### Step 4: ファイルの保存

1. 保存先ディレクトリを作成する:
   ```bash
   mkdir -p .claude/skills/$SKILL_NAME
   ```

2. SKILL.md を保存する:
   ```
   .claude/skills/$SKILL_NAME/SKILL.md
   ```

3. 既に同名のディレクトリが存在する場合は**上書き前にユーザーに確認**する

### Step 5: 完了報告

以下の情報を出力する:

```
## 生成完了

- **Skill名**: $SKILL_NAME
- **保存先**: `.claude/skills/$SKILL_NAME/SKILL.md`
- **元記事**: [$ARTICLE_TITLE]($ARTICLE_URL)
- **対象シナリオ**: [主なシナリオを箇条書き]

`/$SKILL_NAME` で利用できます。
```

## 注意事項

- 記事の内容をそのままコピーするのではなく、**EMの業務に活用できる形に再構成**する
- 著作権に配慮し、記事の本文をそのまま引用するのではなく、知見やフレームワークとして抽出する
- 出典（記事タイトルとURL）は必ず SKILL.md 内に記載する
- 記事の内容がEM業務に直接関係しない場合は、その旨をユーザーに伝え、どの側面をSkill化するか相談する
- 生成した SKILL.md は git commit しない（ユーザーが内容を確認・編集してからコミットする想定）
