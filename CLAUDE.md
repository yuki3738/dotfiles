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

### Adding New Dotfiles
1. Add the file to the repository root
2. Update the `DOT_FILES` array in `setup.sh` to include the new file
3. Run `./setup.sh` to create the symlink

## Architecture

- **Dotfile Management**: Uses symlinks from `~/src/github.com/yuki3738/dotfiles/` to `~/`
- **Shell**: Zsh with oh-my-zsh framework (managed as git submodule)
- **Version Managers**: Uses anyenv for managing multiple language environments (pyenv, goenv, etc.)
- **Repository Management**: Uses ghq with root directory at `~/src`

## Key Configuration Files

- `.zshrc`: Main shell configuration, loads oh-my-zsh and sets up development environments
- `.gitconfig`: Git configuration with ghq integration and custom aliases
- `.tmux.conf`: Terminal multiplexer configuration with vi-mode key bindings
- `.vimrc` & `.ideavimrc`: Editor configurations for Vim and IntelliJ IDEA

## Important Notes

- The `.zsh.d` directory is referenced in `setup.sh` but doesn't currently exist in the repository
- Environment-specific credentials are stored in `.github_credentials` (not version controlled)
- Recent additions include kiro terminal tool configuration