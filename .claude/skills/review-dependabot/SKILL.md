---
name: review-dependabot
description: |
  Dependabot セキュリティアラートをレビューする。
  トリガー: "/review-dependabot <URL>"
  使用場面: Dependabotアラートの影響度評価と対応方針の決定
---

# Review Dependabot

Dependabot セキュリティアラートをレビューしてください。

## 引数
URL: $ARGUMENTS

## 手順

### 1. アラート情報の取得
URLからオーナー、リポジトリ名、アラート番号を抽出し、GitHub APIでアラート情報を取得する：
```
gh api repos/{owner}/{repo}/dependabot/alerts/{number}
```

### 2. 既存対応の確認
同一CVEへの既存PRや対応を確認する：
```bash
gh pr list --search "CVE-XXXX-XXXXX"
gh pr list --search "<パッケージ名> security"
```

### 3. 影響範囲の調査
以下を調べる：
- **依存関係の種類**: 直接依存(direct) か 推移的依存(transitive) か
- **マニフェストファイル**: どの `package.json` / `Gemfile` / `yarn.lock` に含まれるか
- **コード内の使用箇所**: 脆弱なパッケージを直接 import/require しているコードがあるか検索する
- **transitive の場合**: どの直接依存パッケージ経由か（lockfileから確認）
- **モノレポの場合**: 複数のlock fileに同じ脆弱性が存在するか確認する

### 4. リスク評価
以下の観点で実質的なリスクを評価する：
- 脆弱性の種類（RCE / DoS / 情報漏洩 など）
- 攻撃ベクトル（外部入力がパッケージに到達するか）
- 本プロジェクトでの利用コンテキスト（サーバー / バッチ / クライアントサイド）
- CVSS スコアと EPSS（悪用可能性）

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
| 脆弱バージョン | {範囲} |
| 修正バージョン | {バージョン} |
| 現在のバージョン | {バージョン} |
| マニフェスト | {ファイルパス} |
| 依存関係 | {direct/transitive}（{経由パッケージ}） |

### 脆弱性の内容
{脆弱性の簡潔な説明}

### 影響度の評価
{直接使用の有無、攻撃到達可能性、実質的リスクの分析}

### 対応方針
{具体的な対応手順の提案}
```

## 修正方法の優先順位

| 優先度 | 方法 | 説明 |
|--------|------|------|
| 1 | パッケージの公式アップデート | メンテナーがテスト済み、最も安全 |
| 2 | 上位パッケージのアップデート | 依存元を更新して間接的に解決 |
| 3 | resolutions/overrides | 強制上書き、最後の手段 |

## 注意事項
- 実質的なリスクが低い場合もその理由を明確に説明する
- 対応方針は具体的なコマンド（yarn upgrade, bundle update 等）を含める
- transitive dependency の場合、直接依存のアップデートで解決できるか確認する
- 既存の security-review スキルのアンチパターンに従う
