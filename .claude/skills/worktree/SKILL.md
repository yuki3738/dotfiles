---
name: worktree
description: 作業内容の説明から適切なブランチ名とディレクトリを生成し、git worktreeをセットアップしてください。
---

作業内容: $ARGUMENTS

実行手順:

1. 作業内容から適切なブランチ名を生成
   - 英語、小文字、ハイフン区切り
   - 命名規則:
     - feature/機能追加
     - fix/バグ修正
     - refactor/リファクタリング
     - docs/ドキュメント
     - test/テスト追加・修正
     - chore/雑務・設定変更

2. git worktreeを作成（リポジトリ外に配置）
   git worktree add ../リポジトリ名-ブランチ名 -b ブランチ名 origin/main

例：
   movinc/
   ├── kutikomi-com/                         # 元のリポジトリ
   └── kutikomi-com-refactor-strong-params/  # worktree

3. 作成結果を表示
- git worktree list で確認
- 作成したディレクトリのパスを表示

出力形式:

【作成したworktree】
- ブランチ名: {生成したブランチ名}
- フルパス: {絶対パス}
- ベースブランチ: origin/main

【次のステップ】
cd ../{ディレクトリ名}

注意事項:
- mainブランチから分岐（masterではない）
- ブランチ名は簡潔に（50文字以内）
- 日本語の作業内容から意味を汲み取って英語のブランチ名に変換
- worktreeはリポジトリ外（親ディレクトリ）に作成する（.gitignore不要、混乱防止）
