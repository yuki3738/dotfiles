---
name: parallel-worktrees
description: 並列Claude Code作業のためのgit worktreeセットアップ
---

# 並列Claude Code作業のためのgit worktreeセットアップ

複数のタスクを並列でClaude Codeセッションにて実行するため、git worktreeを作成・管理する。

## 入力

$ARGUMENTS

## 使用方法

### 1. 並列タスク作成モード

複数タスクをカンマ区切りで指定すると、各タスク用のworktreeを作成：

```
/parallel-worktrees タスク1の説明, タスク2の説明, タスク3の説明
```

### 2. 管理コマンドモード

```
/parallel-worktrees list        # 現在のworktree一覧
/parallel-worktrees clean       # 完了したworktreeを削除提案
```

---

## 実行手順

### 引数が「list」の場合

1. `git worktree list` を実行
2. 各worktreeの状態を確認
3. 見やすく一覧表示

### 引数が「clean」の場合

1. `git worktree list` で全worktree取得
2. 各worktreeのマージ状況を確認（`git branch --merged main`）
3. 削除候補を提示し、ユーザー確認後に削除

### 引数がタスク指定の場合

1. **タスク解析**
   - カンマ区切りでタスクを分割
   - 各タスクに対してブランチ名を生成

2. **ブランチ命名規則**
   - 英語、小文字、ハイフン区切り
   - プレフィックス:
     - `feature/` 機能追加
     - `fix/` バグ修正
     - `refactor/` リファクタリング
     - `docs/` ドキュメント
     - `test/` テスト追加・修正
     - `chore/` 雑務・設定変更

3. **worktree作成**
   各タスクに対して：
   ```bash
   git worktree add ../リポジトリ名-ブランチ名 -b ブランチ名 origin/main
   ```

4. **結果出力**

---

## 注意事項

- mainブランチから分岐（masterではない場合はリポジトリに応じて変更）
- worktreeはリポジトリの親ディレクトリに作成（混乱防止）
- 各worktreeは独立しているため、並列編集しても干渉しない
- 完了後は `git worktree remove` で削除してクリーンに保つ
- 同じブランチで複数のworktreeは作成できない

## 並列作業のベストプラクティス

1. **タスクの独立性を確認**: 同じファイルを編集するタスクは並列に向かない
2. **環境初期化**: 各worktreeで `bundle install` や `yarn install` が必要な場合がある
3. **定期的なrebase**: 長時間作業する場合は定期的にmainをrebase
4. **完了後のクリーンアップ**: マージ後はworktreeを削除
