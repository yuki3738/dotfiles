export PATH="/usr/local/sbin:$PATH"
export PATH=$PATH:./node_modules/.bin
export GOENV_ROOT=$HOME/.goenv
export PATH=$GOENV_ROOT/bin:$PATH

eval "$(anyenv init -)"

export LC_ALL=en_US.UTF-8
export ZSH=$HOME/src/github.com/yuki3738/dotfiles/oh-my-zsh

GITHUB_CREDENTIAL_FILE=~/.github_credentials
if [ -e $GITHUB_CREDENTIAL_FILE ]; then
  source $GITHUB_CREDENTIAL_FILE
fi

ZSH_THEME="fino"
ZSH_CUSTOM=${HOME}/src/github.com/yuki3738/dotfiles/.zsh.d
plugins=(git ruby osx bundler rails themes)
source $ZSH/oh-my-zsh.sh
setopt nonomatch
export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"
alias ssh='~/bin/ssh-change-profile.sh'
alias lg='lazygit'

# opam configuration
test -r /Users/minamiya/.opam/opam-init/init.zsh && . /Users/minamiya/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
