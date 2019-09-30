#!/bin/bash

ln -sf ${HOME}/src/github.com/yuki3738/dotfiles/.zsh.d ~/.zsh.d

 DOT_FILES=(Brewfile .gitconfig .gitignore .gitignore_global .tmux.conf .vimrc .zshrc .ideavimrc)

for file in ${DOT_FILES[@]}
do
    ln -s ${HOME}/src/github.com/yuki3738/dotfiles/$file $HOME/$file
done
