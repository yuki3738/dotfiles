---
name: rubocop-batch
description: 複数ファイルのRuboCop TODO違反を並列worktreeで一括解消し、1ファイル=1PRで作成する。
---

複数ファイルの RuboCop TODO 違反を**tmux ペイン分割 × worktree** で並列処理し、各ファイルごとに独立した PR を作成する。
各ペインで claude セッションが動く様子をリアルタイムで確認できる。

## 参照ガイド

- **RSpec**: `~/.claude/references/rspec-guide.md`
- **RuboCop**: `~/.claude/references/rubocop-guide.md`
- **既存スキル**: `~/.claude/skills/rubocop-todo-fix/SKILL.md` の Phase 1〜5 に準拠

## 使用方法

```
/rubocop-batch ファイル1 ファイル2 ファイル3
/rubocop-batch app/models/foo.rb app/models/bar.rb app/controllers/baz_controller.rb
```

引数なしで実行すると `.rubocop_todo.yml` から未処理ファイルを自動選出して提案する。

## 引数

- `$ARGUMENTS`: 対象ファイルパス（スペース区切りで複数指定）

## コーディング規約（各 claude セッションに渡すルール）

セッション履歴から抽出した、毎回手動で指摘していたルールを事前適用する。

### RSpec の書き方

1. **lambda/Proc 禁止**: `-> { ... }` や `lambda { ... }` を使わない。ブロック構文 `do...end` を使う
2. **subject 推奨**: `let(:response)` のような呼び出し用変数は `subject` で定義する
3. **既存テストのスタイルに合わせる**: 同じファイル内・同じディレクトリ内のテストの書き方を踏襲する

### コミット・PR

1. **1ファイル = 1PR**: 複数ファイルの修正を1つの PR にまとめない
2. **コミットは1つに squash**: 作業途中のコミットは最終的に1コミットにまとめる
3. **Conventional Commits**: `refactor:` or `style:` プレフィックスを使用
4. **コミットメッセージは日本語**

### RuboCop 修正

1. **`--force-default-config` は使わない**: プロジェクト設定を無視してしまうため
2. **通常の `rubocop <file>` で確認**し、todo の除外を外す前後の差分で対象 Cop を特定
3. **挙動を変えない**: テストが落ちたら実装の修正方法を見直す（テストを変えない）

## 実行手順

### Step 0: 引数チェック

引数が空の場合:
1. `.rubocop_todo.yml` を読み込み
2. 除外ファイル一覧を抽出
3. 最大5件を提案し、ユーザーに選択を求める

### Step 1: Worktree 作成

各ファイルに対して worktree を作成する。

```bash
REPO_NAME=$(basename $(git rev-parse --show-toplevel))

for FILE in $FILES; do
  BASENAME=$(basename "$FILE" .rb)
  BRANCH="refactor/rubocop-${BASENAME}"
  WORKTREE_DIR="../${REPO_NAME}--rubocop-${BASENAME}"
  git worktree add "$WORKTREE_DIR" -b "$BRANCH" origin/main
done
```

### Step 2: tmux セッション起動（ペイン分割方式）

1つのウィンドウ内にペイン分割で全 claude セッションを表示する。

```bash
SESSION_NAME="rubocop-batch"

# 1つ目のペイン（セッション作成）
tmux new-session -d -s "$SESSION_NAME" -c "$WORKTREE_DIR_1" -x 200 -y 60

# 2つ目のペイン（横分割）
tmux split-window -t "${SESSION_NAME}:0" -h -c "$WORKTREE_DIR_2"

# 3つ目のペイン（右側を縦分割）
tmux split-window -t "${SESSION_NAME}:0.1" -v -c "$WORKTREE_DIR_3"

# ペインタイトル表示
tmux set-option -t "$SESSION_NAME" pane-border-status top
tmux set-option -t "$SESSION_NAME" pane-border-format " #{pane_title} "
tmux select-pane -t "${SESSION_NAME}:0.0" -T "ファイル名1"
tmux select-pane -t "${SESSION_NAME}:0.1" -T "ファイル名2"
tmux select-pane -t "${SESSION_NAME}:0.2" -T "ファイル名3"

# 各ペインで claude 起動
tmux send-keys -t "${SESSION_NAME}:0.0" "unset CLAUDECODE && claude --permission-mode auto --model sonnet" Enter
tmux send-keys -t "${SESSION_NAME}:0.1" "unset CLAUDECODE && claude --permission-mode auto --model sonnet" Enter
tmux send-keys -t "${SESSION_NAME}:0.2" "unset CLAUDECODE && claude --permission-mode auto --model sonnet" Enter

# claude の起動完了を待つ
sleep 8

# プロンプト送信（send-keys で1行テキストとして送る）
tmux send-keys -t "${SESSION_NAME}:0.0" "${PROMPT} 対象: ${FILE1}" Enter
tmux send-keys -t "${SESSION_NAME}:0.1" "${PROMPT} 対象: ${FILE2}" Enter
tmux send-keys -t "${SESSION_NAME}:0.2" "${PROMPT} 対象: ${FILE3}" Enter
```

**重要な実装詳細:**

1. **`unset CLAUDECODE`**: 現在の Claude Code セッションから tmux 経由で起動すると `CLAUDECODE` 環境変数が引き継がれ、ネストセッションとしてブロックされる。**必ず前置する**
2. **`--permission-mode auto`**: 各セッションが自律的に動作するために必要（edit/bash を自動許可）
3. **`--model sonnet`**: バッチ処理にはコスト効率の良い sonnet を使用（必要に応じて opus に変更可）
4. **対話モードで起動**（`-p` は使わない）: `-p` だと完了まで画面に何も表示されない。対話モードならリアルタイムで進捗が見える
5. **プロンプトは `send-keys` で1行テキストとして送る**: `load-buffer` / `paste-buffer` は `tmux -CC` モードで動作しない。改行を含むプロンプトファイルも使えないため、1行に凝縮して `send-keys` で送る
6. **sleep 8**: claude 起動完了まで十分待つ。短すぎるとプロンプトが無視される
7. **ペイン分割方式**: ウィンドウ（タブ）方式ではなく、1ウィンドウ内のペイン分割を使う。`tmux -CC attach` するとiTerm2で画面分割として表示される

### Step 3: ユーザーへの案内

```
【RuboCop バッチ処理を開始しました】

tmux セッション: rubocop-batch
処理中のファイル:
  ペイン 0: app/models/foo.rb     (worktree: ../kutikomi-com--rubocop-foo)
  ペイン 1: app/models/bar.rb     (worktree: ../kutikomi-com--rubocop-bar)
  ペイン 2: app/controllers/baz.rb (worktree: ../kutikomi-com--rubocop-baz)

リアルタイムで確認（iTerm2）:
  tmux -CC attach -t rubocop-batch
```

---

### プロンプトテンプレート（send-keys 用の1行版）

`{ファイルパス}` を置換して `send-keys` で送信する。

```
以下のファイルのRuboCop TODO違反(Naming/PredicateMethod)を解消しPRを作成して。自律的に完了させて。手順: 1. .rubocop_todo.ymlで除外Copを特定 2. docker compose run --rm app bundle exec rubocop対象ファイルで違反確認 3. テスト精査・拡充(修正前に実施) 4. 違反を修正(挙動変えない) 5. .rubocop_todo.ymlから削除 6. テスト実行確認 7. 1コミットにまとめてgh pr create。規約: lambda禁止(do...end使う)、subject推奨、--force-default-config禁止、テスト落ちたら実装を見直す。 対象: {ファイルパス}
```

---

### Step 4: 結果確認

```bash
# 作成された PR を一覧
gh pr list --author @me --state open --search "rubocop"

# worktree の一覧
git worktree list
```

完了後のクリーンアップ:

```bash
# tmux セッション終了
tmux kill-session -t rubocop-batch

# worktree 削除（マージ済みのもの）
git worktree list | grep rubocop | awk '{print $1}' | xargs -I{} git worktree remove {}
```

## 制約事項

- テストが通らない状態で PR を作成しない
- 挙動を変える修正を行う場合は、テストを変更するのではなく実装を見直す
- セキュリティに関わる変更は慎重に行う
- 変更範囲外のコードは修正しない
- 同じファイルを編集するタスクは並列にしない
- main ブランチには絶対に push しない
- **docker compose を使うタスクは Docker リソースの競合に注意**（同時に多数の `docker compose run` が走る）
- **tmux ペインは最大4つまで**を推奨（画面の可読性とリソース消費のバランス）
