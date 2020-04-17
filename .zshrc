export PATH="/usr/local/var:/usr/local/bin:/bin:/usr/sbin:/sbin:/usr/bin:"
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

export LC_ALL=en_US.UTF-8
export ZSH=$HOME/src/github.com/yuki3738/dotfiles/oh-my-zsh
ZSH_THEME="fino"
ZSH_CUSTOM=${HOME}/src/github.com/yuki3738/dotfiles/.zsh.d
plugins=(git ruby osx bundler rails themes)
source $ZSH/oh-my-zsh.sh
setopt nonomatch
export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"
alias ssh='~/bin/ssh-change-profile.sh'
alias lg='lazygit'
