---
name: invite-github-members
description: movinc/infrastructure リポジトリを編集し、GitHub Organization (movinc) にメンバーを招待してチーム（Biz等）に追加するDraft PRを自動作成する。
  トリガー: 「GitHubに招待」「Bizチームに追加」「メンバー招待」「org invite」「movincに招待」などの発言。
  使用場面: 新入社員のGitHub Org招待、既存メンバーの所属チーム変更、複数人の一括招待。
---

movinc/infrastructure の Terraform 定義を更新して、GitHub Organization へのメンバー招待と
チーム所属を一括でPR化する。

## 対象ファイル

- `stacks/github/members/memberships.tf` — Organization メンバーシップ（招待）
- `stacks/github/members/teams.tf` — チーム所属

両ファイルとも `locals` ブロック内のリストに追記する。Terraform state操作は不要（宣言的）。

## 前提

- 作業対象リポジトリは `~/src/github.com/movinc/infrastructure`
- ベースブランチは `main`
- PRは **必ずDraftで作成**（グローバル CLAUDE.md 準拠）

## 使用方法

### 対話式（推奨）

```
/invite-github-members
```

ユーザーに以下を聞く:
1. 招待するメンバー一覧（氏名・GitHubハンドル・所属部署・追加先チーム）
2. 追加先チーム（デフォルト: Biz）

### 引数指定

```
/invite-github-members <team-name>
```

例: `/invite-github-members Biz`

## 実行手順

### Step 1: 情報収集

ユーザーから以下の情報を受け取る（不足があれば確認）:

- **フルネーム**（漢字/ローマ字）
- **GitHubアカウント**（ハンドル）
- **所属部署**（PR descriptionに記載）
- **追加先チーム**（Biz / Flamingo / Penguin / Eagle など `teams.tf` の `locals.teams` キー）

複数人同時追加にも対応する。

### Step 2: リポジトリ状態確認

```bash
cd ~/src/github.com/movinc/infrastructure
git fetch origin main
git status
```

- 作業ディレクトリがクリーンか確認
- クリーンでない場合はユーザーに判断を仰ぐ

### Step 3: ブランチ作成

```bash
git checkout -b feature/add-<team>-members-<count>users origin/main
```

命名例: `feature/add-biz-team-10members`, `feature/add-flamingo-member`

### Step 4: memberships.tf 編集

`stacks/github/members/memberships.tf` の `locals.members` リスト**末尾**に追記する。
1人1行、右側にコメントで日本語氏名を書く。カラムは既存エントリに合わせてスペース揃え。

```hcl
    "<github-handle>",   # <氏名>
```

**注意**: `members` リストは追加順（時系列）で積まれている。ABC順ソートはしない。

### Step 5: teams.tf 編集

`stacks/github/members/teams.tf` の該当チーム配列に**アルファベット順（大文字小文字無視）で挿入**する。

例外: Bizリスト先頭の `ricerice555` は順序対象外（そのまま先頭に残す）。それ以降は昇順。

```hcl
    <TeamName> = [
      "既存エントリ",
      "<new-github-handle>",  ← アルファベット順で挿入
      ...
    ]
```

### Step 6: フォーマットチェック

```bash
# mise環境でterraform fmt
(cd stacks/github/members && terraform fmt -check) || (cd stacks/github/members && terraform fmt)
```

mise/terraformが見つからない場合はスキップしてCIに委ねる（手元環境差のため）。

### Step 7: コンフリクト対策

main が進んでいる場合、`stash → checkout -b from origin/main → stash pop` 方式で
新ブランチを作ると他の更新を取り込める。コンフリクトが出たら手動解消してから進める。

### Step 8: コミット

Conventional Commits 形式、日本語本文:

```
feat: add N members to <Team> team

- <github-handle> (<氏名>)
- ...
```

### Step 9: Push & Draft PR 作成

```bash
git push -u origin <branch>
gh pr create --draft --title "<title>" --body "..."
```

**PR description テンプレート**:

```markdown
## Summary

<Team>部門メンバーN名をmovinc OrganizationにInviteし、<Team>チームに追加する。

- <追加理由・背景（ユーザー確認必須）>

追加メンバー:
- <handle> (<氏名>) — <所属部署>
- ...

## Test plan

- [ ] `terramate fmt --check` / `terraform fmt -recursive -check` が通る
- [ ] CI の `terraform plan` で stacks/github/members の差分が期待通り（N名のmembership追加 + <Team>チームへのメンバー追加）であること
```

**重要**: PR作成前に「なぜこのPRを作るのか（背景）」をユーザーに必ず確認する（グローバル CLAUDE.md 準拠）。

**⚠️ バッククォートのエスケープ禁止**: `gh pr create --body "$(cat <<'EOF' ... EOF)"` で HEREDOC を使う場合、
`'EOF'` でシングルクォート指定しているため変数展開されない → バッククォートを `\`` とエスケープしてはいけない。
素のバッククォート（` ` ` `）で書く。誤ってエスケープするとPRに `\`` とそのまま出てしまう。

## よくあるパターン

### 単発追加

1名だけ追加する場合もフローは同じ。ブランチ名は `feature/add-<handle>-to-<team>-team` で短縮可。

### 複数チーム所属

1人のメンバーを複数チームに入れる場合、`teams.tf` の各チーム配列に追加する。
`memberships.tf` は1エントリのみ。

### 既存メンバーのチーム変更

- `memberships.tf` は触らない
- `teams.tf` のみ編集（旧チームから削除 / 新チームに追加）

### Owner権限付与

通常は不要。付与する場合は `memberships.tf` の `owners` リストにも追加する。

## 参考: 過去PR

- #228: `feat: add mov-satoh, KazNem, rnakamura-ctrl to Biz team`
- #240: `feat: add 10 members to Biz team`

どちらも同じパターン。類似作業時は diff を参照すると早い。
