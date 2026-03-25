---
name: cc-update-summary
description: Claude Codeの指定バージョン（または最新版）のリリースノートを取得し、日本語で簡潔にまとめる。「Claude Codeの更新内容」「アプデ内容」「何が変わった」「cc-update-summary」「最新バージョン」などの発言でも使用する。
argument-hint: "[バージョン番号] (例: 2.1.80)"
---

# cc-update-summary

Claude Codeのリリースノートを取得し、日本語で簡潔にまとめるスキル。

## 引数

- `$ARGUMENTS` にバージョン番号が指定されていればそのバージョンを調査する（例: `2.1.80`）
- 引数がなければ最新バージョンのリリースノートを取得する

## 手順

1. WebSearchで `Claude Code <バージョン> release notes site:github.com/anthropics/claude-code` を検索する
2. WebFetchで `https://github.com/anthropics/claude-code/releases` からリリースノートを取得する
   - 特定バージョンが指定されている場合: `https://github.com/anthropics/claude-code/releases/tag/%40anthropic-ai%2Fclaude-code%40<version>` も試す
3. 取得した情報を以下のフォーマットで日本語にまとめる

## 出力フォーマット

```markdown
## Claude Code v<バージョン> リリースノート（<リリース日>）

### 新機能
- **機能名** — 簡潔な説明

### バグ修正
- **修正内容** — 簡潔な説明

### 改善
- **改善内容** — 簡潔な説明

---

**注目ポイント**: 特にインパクトの大きい変更を1〜2点ピックアップして補足する。

Sources:
- [リリースページ](URL)
```

## ルール

- 各項目は1行で簡潔に書く。冗長な説明は不要
- 技術用語はそのまま使い、無理に和訳しない（例: WebSocket, MCP, fine-grained tool streaming）
- リリースノートに記載されていない情報は絶対に書かない
- カテゴリに該当する項目がない場合はそのカテゴリを省略する
