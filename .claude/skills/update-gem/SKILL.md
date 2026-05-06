---
name: update-gem
version: 2.0.0
description: kutikomi-com の Ruby gem アップデートを安全に行い、Draft PR を作成する個人スキル。「gem アップデート」「bundle update」「deps 更新」「Dependabot」関連の発言で使用
keywords: bundle, gem, update, outdated, アップデート, deps, dependabot, kutikomi
proactive: false
---

# Update Gem Skill (user scope)

## 概要

kutikomi-com で Ruby gem を 1 つアップデートし、プロジェクトの慣習に沿った Draft PR を作成するワークフロー。

定期的な細かい deps 更新（`mcp`, `aws-sdk-s3`, `erb` など）を Dependabot 風の 1 PR / 1 gem 粒度で量産することを想定する。

このスキルは個人運用版（user scope, name: `update-gem`）で、プロジェクトには別名の旧スキル `gem-update`（`.claude/skills/gem-update/SKILL.md`）が存在するが、こちらは name を分け、プロジェクト慣習・PR テンプレ・検証手順をすべて最新に揃えたバージョン。

## 使用方法

### アップデート可能な gem の確認

```
/update-gem list
```

`docker compose run --rm app bundle outdated` を実行し、更新可能な gem を表示する。

### 特定の gem をアップデート

```
/update-gem <gem名>
```

指定 gem を 1 つだけ更新し、Draft PR まで作成する。

## ワークフロー

### 1. 既存 PR の重複チェック

```bash
gh pr list --search "<gem名> in:title" --state open
```

同じ gem の更新 PR が既に open ならユーザーに報告して中断 / 続行を確認する。

### 2. 現在のバージョンと最新版の確認

```bash
# 現在の resolved version
grep -nE "^    <gem名> \(" Gemfile.lock

# 最新版とリリース日・依存
curl -s https://rubygems.org/api/v1/gems/<gem名>.json | ruby -rjson -e 'd=JSON.parse(STDIN.read); puts "latest: #{d["version"]}"; puts "source: #{d["source_code_uri"]}"; puts "deps:"; d["dependencies"]["runtime"].each{|x| puts "  - #{x["name"]} #{x["requirements"]}"}'

# 履歴
curl -s https://rubygems.org/api/v1/versions/<gem名>.json | ruby -rjson -e 'JSON.parse(STDIN.read).first(10).each{|v| puts "#{v["number"]}\t#{v["created_at"][0..9]}"}'
```

**用語に注意:** `Gemfile` 側で `gem "foo"`（バージョン制約なし）と書かれているケースは「pin されていない」状態。「ロックされている」と表現しないこと（`Gemfile.lock` の resolved version は pin とは別物）。`Gemfile` 側に `~> X.Y` や `< X` の制約がある場合のみ、Gemfile 側の変更要否を判断する。

### 3. 0.x 系 gem の追加注意

`0.x.y` の gem は SemVer 上 minor bump でも breaking の可能性がある。リリースノートでの破壊的変更の有無を **必ず** 確認する。

### 4. ハイリスク gem の警告

以下の gem が更新対象（または依存解決で巻き込まれる場合）はユーザーに継続確認を取る：

| Gem | 理由 |
|---|---|
| rack | Rails 全体に影響 |
| rails | フレームワーク本体 |
| sidekiq | バックグラウンドジョブ全体 |
| devise | 認証システム全体 |
| elasticsearch | 検索機能全体 |
| puma | 本番 web サーバ |
| pg / mysql2 | DB ドライバ |

### 5. ライブラリの役割と使用箇所の調査

#### 役割

GitHub の README / リリースノート / `source_code_uri` を確認し「何を解決するライブラリか」を 1〜2 文で言語化する。

#### 使用箇所の特定（vendor / node_modules を除外）

```bash
grep -rn "<gem名>\|<主要クラス名>" --include="*.rb" --include="*.rake" \
  --exclude-dir=vendor --exclude-dir=node_modules \
  app/ lib/ config/ spec/
```

#### server/client API の分類（重要）

サーバー機能とクライアント機能の両方を提供する gem（例: `mcp`, `redis`, `aws-sdk-*`）では、**当アプリが使っている API 表面** を切り分ける：

- 当アプリが使っている API（=変更がある場合は影響評価対象）
- 当アプリが使っていない API（=変更があっても無関係と明記できる）

PR description の影響評価表で「使っている／使っていない」軸で分類すると、レビュアーの判断コストが下がる。

### 6. リリースノートと差分の取得

```bash
# リリースノート
curl -s https://api.github.com/repos/<owner>/<repo>/releases/tags/v<version> | ruby -rjson -e 'd=JSON.parse(STDIN.read); puts d["body"]'

# コミット差分
curl -s "https://api.github.com/repos/<owner>/<repo>/compare/v<old>...v<new>" | ruby -rjson -e 'd=JSON.parse(STDIN.read); puts "ahead: #{d["ahead_by"]} commits"; d["commits"].each{|c| puts "* #{c["commit"]["message"].lines.first.strip}"}'

# ファイル単位の変更規模
curl -s "https://api.github.com/repos/<owner>/<repo>/compare/v<old>...v<new>" | ruby -rjson -e 'JSON.parse(STDIN.read)["files"].each{|f| puts "#{f["status"]}\t+#{f["additions"]} -#{f["deletions"]}\t#{f["filename"]}"}'
```

特に **当アプリで使っている API（5 で分類した側）に変更が乗っていないか** を diff で確認する。

### 7. ブランチ作成と更新実行

```bash
# main を最新化
git fetch origin main --quiet
git checkout -b update-<gem名>-to-<version> origin/main

# 更新（同時に他の gem を巻き込まないよう conservative を必ず付ける）
docker compose run --rm app bundle update --conservative <gem名>

# 差分確認
git diff --stat
git diff Gemfile.lock
```

ブランチ名は **必ず `update-<gem名>-to-<version>` 形式**（`chore/` プレフィックスは付けない。既存の deps PR 全てこの形式: `update-erb-to-6.0.3`, `update-bootsnap-to-1.23.0`, `update-aws-sdk-s3-to-1.219.0`）。

作業前に他ブランチに居る場合は、**作業終了後に元ブランチへ戻す** ことを忘れない（`git checkout <元のブランチ>`）。

### 8. 関連 spec での検証

「使っている API 表面」に対応する spec を絞って実行する。フルテストは CI に任せ、ローカルでは 30 秒程度で済む範囲に留める。

```bash
docker compose run --rm app bin/rspec spec/<関連ディレクトリ>
```

例: `mcp` 更新時 → `spec/requests/mcp spec/models/mcp spec/app/models/mcp`

### 9. コミット作成

**フォーマット（プロジェクト慣習で固定）：**

```
chore(deps): <gem名> を <旧version> から <新version> にアップデート

<リリースノートの要約 or 影響評価>
- 主な変更点1
- 主な変更点2

<当アプリへの影響に関する所見（破壊的変更なし／使っていない API のみ等）>
```

例: `chore(deps): mcp を 0.13.0 から 0.14.0 にアップデート`

### 10. Push と Draft PR 作成

**PR は必ず Draft で作成する**（CLAUDE.md グローバルルール）。

```bash
git push -u origin update-<gem名>-to-<version>

gh pr create --draft --base main --head update-<gem名>-to-<version> \
  --title "chore(deps): <gem名> を <旧version> から <新version> にアップデート" \
  --body "$(cat <<'EOF'
## Summary

### なぜ
- 現在 `Gemfile.lock` に記録されている `<gem名> <旧version>`（YYYY-MM-DD リリース）に対し、上流で `<新version>`（YYYY-MM-DD リリース）が公開されたため定期アップデートする。
- <新version> は <破壊的変更なし／あり> で、<機能追加 / バグ修正 / リファクタ> 中心。

### 変更内容
- `Gemfile.lock` の `<gem名>` を `<旧>` → `<新>` に更新
- ランタイム依存への影響: <なし／〇〇が x.y.z → a.b.c に連動>

### <新version> の主な変更（影響評価）

| 変更 | 当アプリへの影響 |
|---|---|
| 変更点A | 当アプリの <使用箇所> に該当／該当せず |
| 変更点B | オプトインのため未使用なら無関係 |
| 変更点C | client 側のみの変更で当アプリは server 側のみ利用のため無影響 |

当アプリは <利用箇所のサマリ> でのみ利用しており、上記の変更による挙動差は発生しない。

### やらないこと
- <新機能Aの利用>（別 PR で検討）
- <設定変更>

## Test plan

- [x] `bundle update --conservative <gem>` で差分が `Gemfile.lock` の <該当> 行のみであることを確認
- [x] 関連 spec の実行: `bin/rspec <パス>` が <N> examples 0 failures
- [ ] CI（RSpec / RuboCop / Brakeman 等）がグリーン
EOF
)"
```

PR タイトルもブランチ名・コミットメッセージと揃える。`🤖 Generated with Claude Code` の脚注は **付けない**（既存の deps PR に付いていないため）。

### 11. 元のブランチへ復帰

ユーザーが別ブランチで作業中だった場合、作業を阻害しないよう元のブランチへ戻す：

```bash
git checkout <元のブランチ名>
```

## チェックリスト

- [ ] 既存 PR の重複チェック完了
- [ ] 0.x 系の場合は破壊的変更を確認した
- [ ] ハイリスク gem の場合はユーザー確認を取った
- [ ] 当アプリが使っている API 表面を特定した
- [ ] リリースノートと commits 一覧を確認した
- [ ] ブランチ名は `update-<gem>-to-<version>`
- [ ] コミットメッセージは `chore(deps): <gem> を <旧> から <新> にアップデート`
- [ ] `bundle update --conservative` で差分が想定範囲内
- [ ] 関連 spec をローカルで実行してグリーン
- [ ] PR は **Draft** で作成
- [ ] PR description は「なぜ → 変更 → 影響評価 → やらないこと → Test plan」構造
- [ ] 元ブランチに戻した

## メジャーアップデート時の追加対応

メジャーバージョン（1.x → 2.x）の場合：

1. リリースノートで Breaking Changes を全て列挙
2. 当アプリの利用 API に対する影響を 1 つずつ評価
3. 必要なコード修正があれば **同 PR に含める**（gem 更新だけ先行マージしない）
4. 移行ガイド（Migration Guide）が公式にあれば PR description に必ず引用

## 参考

- プロジェクト慣習: `git log --oneline --grep="chore(deps):" -20` で過去の deps PR 形式を確認
- ブランチ命名前例: `update-erb-to-6.0.3`, `update-bootsnap-to-1.23.0`, `update-aws-sdk-s3-to-1.219.0`
- Bundler: https://bundler.io/
- RubyGems API: https://guides.rubygems.org/rubygems-org-api/
