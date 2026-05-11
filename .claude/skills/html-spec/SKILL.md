---
name: html-spec
description: >
  仕様書・実装計画を「読まれる」HTMLアーティファクトとして生成する。
  モックアップ・データフロー図（SVG）・実装ステップ・影響範囲・リスクを
  単一HTMLファイルにまとめる。Markdownの仕様書より共有・閲覧されやすい。
  「仕様書をHTMLで」「実装計画HTML」「specをHTMLにして」「設計をビジュアルで」
  「html-spec」などの発言で使用する。
  Thariq Shihipar (@trq212) の "Unreasonable Effectiveness of HTML" を踏まえ、
  Markdownの代替ではなく**配布物としてのHTML**を生成することに特化する。
user-invocable: true
allowed-tools: Bash, Read, Write, Glob, Grep
argument-hint: <仕様化したいトピック> [出力先パス(省略可)]
---

# /html-spec — 仕様・実装計画のHTMLアーティファクト生成

仕様書・実装計画を「読まれる確率を上げる」ために、構造化されたHTMLファイルとして
生成する。テキストの羅列ではなく、モックアップ・図・表・色分けで情報を立体化する。

---

## あなたの役割

経験豊富なシニアエンジニア兼テクニカルライター。読み手は「実装担当者」「レビュアー」
「PdM/EM/関係チーム」を想定し、**問題定義・解決案・実装手順・影響範囲・リスク** を
過不足なく整理する。

---

## 設計思想（Thariq記事準拠）

- HTMLは**配布物**であり、Markdownの置き換えではない
- 「**何を作るか**」を毎回考える。テンプレート機械生成にならないよう、トピックに応じて
  セクション構成・図表の種類を取捨選択する
- インタラクティブ要素は **JavaScriptに依存しすぎない**（Obsidian埋め込みやS3配布で
  scriptが剥がされるケースに備え、CSSと`<details>`で代替できる場合はそちらを優先）
- スタイルは**インラインCSS**で完結させる（CDN依存を避けてオフライン・社内ネット環境で
  も開ける）

---

## インプット

### 必須

- **仕様化したいトピック**: 自然言語でOK
  - 例: 「カジュアル面談のフィードバックを社内に流す仕組み」
  - 例: 「mov-core の Search API を多言語対応にする実装計画」

### 任意

- **出力先パス**: 保存先（指定なければ `tmp/specs/{YYYY-MM-DD}_{slug}.html`）
- **参照ファイル**: 既存コード・既存仕様のパス（あれば Read で読み込む）
- **対象オーディエンス**: 実装者向け / レビュー向け / 経営報告向け 等

---

## 実行ステップ

### Step 1: トピックの理解と前提整理

1. ユーザー入力からトピックを抽出
2. 参照ファイル指定があれば `Read` / `Grep` で読み込み、既存仕様・既存コードの状態を把握
3. **不明点が3つ以上ある場合は AskUserQuestion で先にヒアリング**（推測で埋めない）

### Step 2: セクション構成の決定

トピックの性質に応じて、以下から必要なセクションを取捨選択する（全部入れる必要はない）:

| セクション | 入れる判断基準 |
|---|---|
| 1. 概要・目的 | 必須 |
| 2. 背景・課題 | 既存システムを変更する場合 |
| 3. ユーザーストーリー / 要件 | プロダクト機能の場合 |
| 4. モックアップ | UI変更がある場合 |
| 5. データフロー図 | API/データの流れが変わる場合 |
| 6. 実装ステップ | 必須（実装計画の中核） |
| 7. 影響範囲・破壊的変更 | 既存機能への影響がある場合 |
| 8. リスク・代替案 | 不確実性が高い場合 |
| 9. 検証計画 | テスト方法が非自明な場合 |
| 10. オープン質問 | 設計判断が未確定な場合 |

### Step 3: HTML生成

下記の **HTMLテンプレート** をベースに、Step 2 で決めたセクション構成でファイルを書く。
モックアップ・データフロー・実装ステップは可能な限り**ビジュアル化**する。

#### スタイル方針

- **インラインCSS**で完結（CDN/外部ファイル禁止）
- 配色: 落ち着いた中性色（背景 `#fafafa`、本文 `#1a1a1a`、アクセント `#2563eb`）
- フォント: `system-ui, -apple-system, "Hiragino Sans", "Yu Gothic", sans-serif`
- レスポンシブ: max-width 880px、中央寄せ、印刷でも崩れない
- ダークモード対応は任意（`@media (prefers-color-scheme: dark)`）

#### モックアップ

- UIモックは `<div>` + CSS で擬似的に再現する（Figma埋め込みは不可）
- 複数案を出す場合は `<div class="mockup-grid">` で並べる

#### データフロー / 図

- インラインSVGで描く
- 矩形・矢印・テキストの素朴な構成。色は3色まで（中性色 + アクセント1〜2色）
- 複雑になりすぎたら表（`<table>`）で代替

#### 実装ステップ

- 番号付きのステップカード（`<ol class="steps">`）
- 各ステップに「変更ファイル」「想定差分」「依存」を併記

#### コードスニペット

- `<pre><code>` で。シンタックスハイライトは入れない（軽量化のため）
- 言語が分かるよう、見出しに `// path/to/file.rb` のようにコメントで明記

### Step 4: 保存とアウトプット

1. 生成したHTMLを出力先に保存:
   - 出力先指定あり → そのパスへ保存
   - 指定なし → `tmp/specs/{YYYY-MM-DD}_{slug}.html`（ディレクトリは自動作成）
2. チャットには以下を提示:
   - **保存先のフルパス**
   - macOS なら `open {path}` で開けることを案内
   - 1〜2行の要約（何を含むスペックを書いたか）
3. **HTML全文をチャットに貼り付けない**（長すぎるため。ファイルパスのみ）

---

## HTMLテンプレート（最小骨格）

```html
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{タイトル}</title>
<style>
  :root {
    --bg: #fafafa;
    --fg: #1a1a1a;
    --muted: #6b7280;
    --accent: #2563eb;
    --warn: #d97706;
    --border: #e5e7eb;
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    background: var(--bg);
    color: var(--fg);
    font-family: system-ui, -apple-system, "Hiragino Sans", "Yu Gothic", sans-serif;
    line-height: 1.7;
  }
  .container { max-width: 880px; margin: 0 auto; padding: 48px 24px; }
  h1 { font-size: 28px; border-bottom: 2px solid var(--accent); padding-bottom: 8px; }
  h2 { font-size: 22px; margin-top: 48px; color: var(--accent); }
  h3 { font-size: 18px; margin-top: 32px; }
  .meta { color: var(--muted); font-size: 14px; margin-top: -16px; }
  .steps { list-style: none; padding: 0; counter-reset: step; }
  .steps > li {
    counter-increment: step;
    background: white;
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 16px 20px 16px 56px;
    margin-bottom: 12px;
    position: relative;
  }
  .steps > li::before {
    content: counter(step);
    position: absolute;
    left: 16px; top: 16px;
    width: 28px; height: 28px;
    border-radius: 50%;
    background: var(--accent);
    color: white;
    display: flex; align-items: center; justify-content: center;
    font-weight: bold; font-size: 14px;
  }
  table {
    width: 100%; border-collapse: collapse; margin: 16px 0;
    background: white; border: 1px solid var(--border);
  }
  th, td { padding: 10px 14px; text-align: left; border-bottom: 1px solid var(--border); }
  th { background: #f3f4f6; font-weight: 600; }
  pre {
    background: #1e293b; color: #e2e8f0;
    padding: 16px; border-radius: 6px;
    overflow-x: auto; font-size: 13px;
  }
  code { font-family: "SF Mono", Menlo, monospace; }
  .callout {
    background: #fef3c7; border-left: 4px solid var(--warn);
    padding: 12px 16px; margin: 16px 0; border-radius: 4px;
  }
  .mockup-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
  @media (max-width: 640px) {
    .mockup-grid { grid-template-columns: 1fr; }
  }
</style>
</head>
<body>
  <div class="container">
    <h1>{タイトル}</h1>
    <p class="meta">作成日: {YYYY-MM-DD} / 対象: {オーディエンス}</p>

    <!-- 各セクションをここに -->

  </div>
</body>
</html>
```

---

## 制約・禁止事項

- **推測・捏造禁止**: 既存コード・既存仕様を参照する場合は必ず `Read` で確認してから書く
- **CDN/外部リソース禁止**: Tailwind CDN, Google Fonts, jsDelivr 等は使わない（オフラインで開けなくなる）
- **重い JavaScript 禁止**: 100行を超えるscriptを埋め込む場合は、HTMLを2分割するか、別ファイル運用を検討
- **ファイル名に `:` を使わない**（プロジェクト規約）
- **Markdown版を別途作らない**: HTMLが配布物。中間メモが必要ならチャットで完結させる
- **テンプレートを機械的に当てはめない**: トピックに不要なセクションは省く

---

## エラー時のフォールバック

| 症状 | 対処 |
|------|------|
| トピックが曖昧でセクション構成が決められない | AskUserQuestion で 1〜2点絞ってヒアリング |
| 参照ファイルが大きすぎる | Glob/Grep で関連箇所を絞ってから Read |
| HTML が長くなりすぎる（100KB超） | セクションを分割して複数ファイル化 or データフロー図を表に格下げ |

---

## 補足: Markdown を選ぶべきケース

このスキルを使わず Markdown で書くべきケース:

- Obsidian Vault 内に蓄積する仕様（wikilink・全文検索を活かしたい）
- GitHub PR 本文・Issue 本文（GitHub 上で diff を取りたい）
- README・ADR（バージョン管理で履歴を追いたい）

HTML が活きるのは「**1回読んでもらえれば良い配布物**」。
