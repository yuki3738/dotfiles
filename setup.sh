#!/bin/bash

ln -sf ${HOME}/src/github.com/yuki3738/dotfiles/.zsh.d ~/.zsh.d

DOT_FILES=(.gitconfig .gitignore .gitignore_global .tmux.conf .vimrc .zshrc .ideavimrc .gitmessage .pryrc)

for file in ${DOT_FILES[@]}
do
    ln -sf ${HOME}/src/github.com/yuki3738/dotfiles/$file ${HOME}/$file
done
