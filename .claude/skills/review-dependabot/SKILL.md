---
name: review-dependabot
description: |
  Dependabot セキュリティアラートをレビューし、影響度評価と対応方針を決定する。
  トリガー: "/review-dependabot <URL>"
  使用場面: Dependabotアラートの影響度評価、脆弱性の実質的リスク判定、修正方法の提案。
  「セキュリティアラート」「脆弱性対応」「Dependabot」「CVE」「npm audit」「bundle audit」
  「このアラート見て」「脆弱性を確認して」「セキュリティ修正」などの発言でも使用する。
  個別アラートURL（/dependabot/123）でも一覧URL（/dependabot?q=is:open）でも対応可能。
---

# Review Dependabot

Dependabot セキュリティアラートをレビューする。

## 引数
URL: $ARGUMENTS

## 手順

### 0. URL の解析と分岐

URLからオーナー、リポジトリ名を抽出する。URLの形式に応じて分岐する：

- **個別アラート**（`/security/dependabot/123`）→ アラート番号を抽出し、ステップ1へ
- **一覧ページ**（`/security/dependabot` or `?q=is:open`）→ 全オープンアラートを取得し、サマリーを出力してからユーザーにどのアラートを詳細レビューするか確認する

一覧取得：
```bash
gh api repos/{owner}/{repo}/dependabot/alerts \
  --jq '.[] | select(.state == "open") | {number, severity: .security_advisory.severity, package: .security_vulnerability.package.name, ecosystem: .security_vulnerability.package.ecosystem, summary: .security_advisory.summary}' 
```

### 1. アラート情報の取得

GitHub APIでアラート情報を取得する。`--jq` で必要なフィールドだけ抽出し、コンテキストを節約する：

```bash
gh api repos/{owner}/{repo}/dependabot/alerts/{number} \
  --jq '{
    number,
    state,
    severity: .security_advisory.severity,
    cvss: .security_advisory.cvss,
    cve: (.security_advisory.identifiers[] | select(.type == "CVE") | .value),
    summary: .security_advisory.summary,
    description: .security_advisory.description,
    package: .security_vulnerability.package.name,
    ecosystem: .security_vulnerability.package.ecosystem,
    vulnerable_range: .security_vulnerability.vulnerable_version_range,
    first_patched: .security_vulnerability.first_patched_version.identifier,
    manifest_path: .dependency.manifest_path,
    scope: .dependency.scope,
    references: [.security_advisory.references[].url],
    published_at: .security_advisory.published_at
  }'
```

### 2. 既存対応の確認

同一脆弱性に対する既存の対応を確認する：

```bash
# Dependabotが自動作成したPR（最も見落としやすいので最初に確認）
gh pr list --repo {owner}/{repo} --author "app/dependabot" --search "{パッケージ名}" --state all --json number,title,state --jq '.[] | "\(.number) [\(.state)] \(.title)"'

# 手動対応のPR
gh pr list --repo {owner}/{repo} --search "{CVE番号} OR {パッケージ名} security" --state all --json number,title,state --jq '.[] | "\(.number) [\(.state)] \(.title)"'
```

既にオープンなDependabot PRがある場合は、そのPRのレビュー・マージを推奨する。

### 3. 影響範囲の調査

以下を調べる：

- **依存関係の種類**: ステップ1の `scope` で direct/transitive（runtime/development）を判定
- **マニフェストファイル**: ステップ1の `manifest_path` で特定

**コード内の使用箇所の検索**:
```bash
# リポジトリ内で脆弱なパッケージを直接 import/require しているか
gh api -X GET "search/code?q={パッケージ名}+in:file+repo:{owner}/{repo}" \
  --jq '.items[] | "\(.path):\(.name)"'
```

**transitive dependencyの場合、親パッケージの特定**:

エコシステムに応じたlockfileを確認する：

```bash
# npm (package-lock.json) — 親パッケージを特定
cat package-lock.json | jq '.. | objects | select(.dependencies."{パッケージ名}"?) | keys'

# yarn (yarn.lock) — 依存元を grep で特定
grep -B 5 '"{パッケージ名}@' yarn.lock

# Ruby (Gemfile.lock) — 依存ツリーを確認
bundle exec ruby -e "puts Bundler.load.specs.select{|s| s.dependencies.any?{|d| d.name == '{パッケージ名}'}}.map(&:name)"
```

**モノレポの場合**: 複数の lockfile に同じ脆弱パッケージが存在するか確認する：
```bash
find . -name "package-lock.json" -o -name "yarn.lock" | xargs grep -l "{パッケージ名}"
```

### 4. リスク評価

以下の観点で実質的なリスクを評価する：

- **脆弱性の種類**: RCE / DoS / 情報漏洩 / XSS / SSRF など
- **攻撃ベクトル**: 外部入力（ユーザー入力、APIレスポンス等）が脆弱なパッケージに到達するか
- **利用コンテキスト**: サーバーサイド / バッチ処理 / クライアントサイド / ビルドツール（devDependency）
- **CVSS スコア**: ステップ1で取得済み

**EPSS（悪用可能性）の確認**:
CVE番号が判明している場合、FIRST.org の EPSS API で実際の悪用確率を取得する：
```bash
curl -s "https://api.first.org/data/v1/epss?cve={CVE番号}" | jq '.data[0] | {epss: .epss, percentile: .percentile}'
```
- EPSS > 0.1 (10%): 積極的な悪用が確認されている可能性が高い。優先対応
- EPSS 0.01〜0.1: 中程度のリスク。影響範囲と合わせて判断
- EPSS < 0.01: 悪用の可能性は低いが、CVSS が高ければ対応を検討

### 5. レビュー結果の出力

以下のフォーマットで出力する：

```
## Dependabot Alert #{番号} レビュー

### アラート概要
| 項目 | 内容 |
|------|------|
| パッケージ | {名前} ({ecosystem}) |
| 深刻度 | {severity} (CVSS {score}) |
| CVE | {CVE番号} |
| EPSS | {epss値} ({percentile}パーセンタイル) |
| 脆弱バージョン | {範囲} |
| 修正バージョン | {バージョン} |
| 現在のバージョン | {バージョン} |
| マニフェスト | {ファイルパス} |
| 依存関係 | {direct/transitive}（{経由パッケージ}） |
| 既存PR | {あれば PR 番号とステータス} |

### 脆弱性の内容
{脆弱性の簡潔な説明}

### 影響度の評価
{直接使用の有無、攻撃到達可能性、実質的リスクの分析}

リスクが低い場合も、なぜ低いのかの根拠を明記する（devDependencyのみ、攻撃経路が存在しない等）。

### 対応方針
{具体的な対応手順の提案。下記の優先順位に従い、実行可能なコマンドを含める}
```

### 6. マージ可否コメントの生成（必須）

既存のDependabot PR（または手動対応PR）がある場合、**そのPRにコピペできるマージ可否コメントを必ず生成する**。ユーザーがPRに貼り付けてマージ判断の根拠として使う。

以下のフォーマットで出力する：

```markdown
## マージ可否レビュー: {✅ マージ可 / ⚠️ 要注意 / ❌ マージ不可}

### 脆弱性概要
- **{CVE番号}** ({Severity}, CVSS {score}): {攻撃の本質を1行で}
- 対象: `{マニフェストパス}` の `{パッケージ名}` を `{修正バージョン}` へ更新

### 脆弱性の仕組み
{攻撃チェーンを2〜4行で簡潔に。読み手が「なぜこれを直す必要があるか」理解できる粒度}

### マージして良い理由
- **影響範囲の限定性**: {transitive/devDependency/root側は対応済み 等、実質的な攻撃面の狭さ}
- **直接使用の有無**: {`import/require` の調査結果。自前コードへの影響の有無}
- **破壊的変更の評価**: {バージョンアップ幅（patch/minor/major）と、セキュリティパッチに伴う入力バリデーション変更の有無}
- {その他、このケース固有の安全判断の根拠}

### 放置するとまずい理由
- {runtime scopeなら実行環境でのリスク / Criticalの理由 / EPSSが高い場合の悪用可能性}

### 注意点（マージ時に確認したいこと）
- {該当する場合のみ: 入力バリデーション強化により例外を投げる可能性のある使用箇所 等}
- CI は網羅的ではない前提で判断している（lintと最低限のtest pass は必要条件だが、全実行パスをカバーしていない）
```

**重要な原則（この順序で判断する）**:

1. **「CI 全パス」を安全の十分条件にしない**
   CI が通っていることはマージの**必要条件**に過ぎない。全実行パスを網羅していない限り、それだけで安全と主張してはならない。代わりに「直接使用の有無」「破壊的変更の性質」「影響範囲の限定性」から安全性を論証する。

2. **破壊的変更の可能性を必ず評価する**
   セキュリティパッチは **入力バリデーションを強化する**タイプの変更が多い（CRLFサニタイズ、型チェック、長さ制限など）。これは SemVer 上 minor/patch でも、これまで通っていた入力が例外を投げるようになり、実質的な破壊的変更になる。リリースノート・diff・advisory の "Fix" セクションから確認する。

3. **マージしない判断も選択肢**
   リスクが低く、破壊的変更の可能性が高い場合、「dismiss（false positive/acceptable risk）」も正当な選択肢として提示する。

4. **「放置するとまずい理由」も必ず書く**
   マージ推奨の場合、マージしないときのリスクも明記する。放置の判断をするときも、そのリスクを理解した上で決めるため。

## 修正方法の優先順位

| 優先度 | 方法 | 説明 |
|--------|------|------|
| 0 | 既存Dependabot PRのマージ | 自動PRがある場合はレビュー＆マージが最速 |
| 1 | パッケージの公式アップデート | メンテナーがテスト済み、最も安全 |
| 2 | 上位パッケージのアップデート | transitive依存の場合、親パッケージ更新で間接解決 |
| 3 | resolutions/overrides | 強制上書き。最後の手段。副作用に注意 |

## 注意事項
- 実質的なリスクが低い場合もその理由を明確に説明する
- 対応方針は具体的なコマンド（`yarn upgrade {pkg}`, `npm update {pkg}`, `bundle update {gem}` 等）を含める
- transitive dependency の場合、直接依存のアップデートで解決できるか必ず確認する
- GitHub APIのレスポンスは `--jq` で必要フィールドのみ抽出し、コンテキストを節約する
