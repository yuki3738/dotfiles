# Dotfiles

macOS向けの開発環境設定ファイル（dotfiles）を管理するリポジトリです。

## 概要

このリポジトリは、開発環境の設定を簡単に再現できるように、各種設定ファイルを一元管理しています。シンボリックリンクを使用して、リポジトリ内のファイルをホームディレクトリに配置します。

## 主な機能

- 🚀 ワンコマンドでの環境構築
- 🔧 Zsh + Oh My Zsh による強力なシェル環境
- 📦 anyenv による複数言語のバージョン管理
- 🔍 ghq によるリポジトリ管理
- ⚡ tmux + Vim による効率的な開発環境

## 必要条件

- macOS
- Git
- Homebrew（推奨）

## インストール

### 1. リポジトリのクローン

ghqを使用する場合（推奨）:
```bash
ghq get yuki3738/dotfiles
```

または通常のgit cloneを使用:
```bash
git clone https://github.com/yuki3738/dotfiles.git ~/src/github.com/yuki3738/dotfiles
```

### 2. セットアップスクリプトの実行

```bash
cd ~/src/github.com/yuki3738/dotfiles
./setup.sh
```

### 3. Oh My Zshのサブモジュール初期化

```bash
git submodule update --init --recursive
```

### 4. シェルの再起動

```bash
exec $SHELL
```

## 含まれる設定ファイル

| ファイル | 説明 |
|---------|------|
| `.zshrc` | Zshの設定（Oh My Zsh、エイリアス、PATH設定など） |
| `.gitconfig` | Gitの設定（ユーザー情報、エイリアス、ghq連携） |
| `.gitignore_global` | グローバルなGit除外設定 |
| `.gitmessage` | Gitコミットメッセージテンプレート |
| `.tmux.conf` | tmuxの設定（viキーバインド） |
| `.vimrc` | Vimエディタの基本設定 |
| `.ideavimrc` | IntelliJ IDEA用のVimプラグイン設定 |
| `.pryrc` | Ruby開発用のPryデバッガ設定 |
| `.hyper.js` | Hyperターミナルの設定 |
| `.claude/` | [Claude Code](https://docs.anthropic.com/en/docs/claude-code)の設定（[詳細](.claude/README.md)） |

## 主な開発環境

### シェル環境
- **Zsh** + **Oh My Zsh**: モダンなシェル環境
- **テーマ**: robbyrussell（デフォルト）
- **プラグイン**: git

### 言語バージョン管理
**anyenv**を使用して以下の環境を管理:
- Python (pyenv)
- Go (goenv)
- Ruby (rbenv)
- Node.js (nodenv)

### リポジトリ管理
- **ghq**: Goで書かれたリポジトリ管理ツール
- リポジトリのルートディレクトリ: `~/src`

### エディタ
- **Vim**: 基本的な設定（行番号、検索、インデント）
- **Visual Studio Code**: エディタコマンド `code`
- **IntelliJ IDEA**: Vimキーバインドサポート

## カスタマイズ

### 新しいdotfileを追加する

1. 新しい設定ファイルをリポジトリのルートに追加
2. `setup.sh`内の`DOT_FILES`配列に追加
3. セットアップスクリプトを再実行

例:
```bash
# setup.sh を編集
DOT_FILES=(.gitconfig .gitignore .gitignore_global .tmux.conf .vimrc .zshrc .ideavimrc .gitmessage .pryrc .新しいファイル)
```

### Gitユーザー情報の設定

`.gitconfig`内のユーザー情報を自分のものに変更:
```bash
git config --global user.name "あなたの名前"
git config --global user.email "your.email@example.com"
```

### Zshカスタマイズ

`.zshrc`を編集して、エイリアスや関数を追加できます。また、`.zsh.d/`ディレクトリを作成して、追加の設定ファイルを配置することも可能です。

## トラブルシューティング

### シンボリックリンクが作成されない
- `setup.sh`に実行権限があることを確認: `chmod +x setup.sh`
- 既存のファイルがある場合は、バックアップを取ってから削除

### Oh My Zshが読み込まれない
- サブモジュールが正しく初期化されているか確認
- `.zshrc`内のOH_MY_ZSHパスが正しいか確認

### 環境変数が反映されない
- シェルを再起動: `exec $SHELL`
- `.zshrc`が正しくシンボリックリンクされているか確認
