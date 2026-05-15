# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for macOS development environment configuration. It uses symlinks to deploy configuration files to the home directory.

## Common Commands

### Setup/Installation
```bash
# Deploy all dotfiles to home directory
./setup.sh

# Update oh-my-zsh submodule
git submodule update --init --recursive
```

### Adding New Dotfiles (single files)
1. Add the file to the repository root
2. Update the `DOT_FILES` array in `setup.sh` to include the new file
3. Run `./setup.sh` to create the symlink

### Adding New Dotfile Directories
`.zsh.d` や `.claude` のようなディレクトリは `DOT_FILES` ではなく、`setup.sh` 冒頭で `ln -snf` により個別に symlink している。新しいディレクトリを追加する場合も同様に `setup.sh` へ追記する。

## Architecture

- **Dotfile Management**: 2系統の symlink で構成
  - ファイル系: `DOT_FILES` 配列 (`.zshrc`, `.gitconfig` 等) を `~/` 直下に symlink
  - ディレクトリ系: `.zsh.d`, `.claude` を `setup.sh` 冒頭で個別に `ln -snf`
- **Shell**: Zsh with oh-my-zsh framework (managed as git submodule)
- **Version Managers**: Uses anyenv for managing multiple language environments (pyenv, goenv, etc.)
- **Repository Management**: Uses ghq with root directory at `~/src`
- **Claude Code 設定**: `.claude/` は `~/.claude` への symlink。グローバル設定 (`CLAUDE.md`)、スキル、プラグイン設定を dotfiles 管理下に置く

## Key Configuration Files

- `.zshrc`: Main shell configuration, loads oh-my-zsh and sets up development environments
- `.gitconfig`: Git configuration with ghq integration and custom aliases
- `.tmux.conf`: Terminal multiplexer configuration with vi-mode key bindings
- `.vimrc` & `.ideavimrc`: Editor configurations for Vim and IntelliJ IDEA
- `.claude/CLAUDE.md`: グローバルなClaude Code指示（`~/.claude/CLAUDE.md` の実体）

## Important Notes

- Environment-specific credentials are stored in `.github_credentials` (not version controlled)
- `~/.claude` を dotfiles 配下の `.claude` へ symlink しているため、Claude Code のスキルやプラグイン設定もこのリポジトリに含まれる（一部は `.claude/.gitignore` で除外）