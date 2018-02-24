export PATH="/usr/local/var:/usr/local/bin:/bin:/usr/sbin:/sbin:/usr/bin:"
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

export ZSH=$HOME/src/github.com/yuki3738/dotfiles/oh-my-zsh
ZSH_THEME="fino"
ZSH_CUSTOM=${HOME}/src/github.com/yuki3738/dotfiles/.zsh.d
plugins=(git ruby osx bundler rails themes)
source $ZSH/oh-my-zsh.sh
