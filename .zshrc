# ------------------------------
# PATH の設定
# ------------------------------
export PATH="/usr/local/bin:/usr/local/sbin:/opt/homebrew/bin:$HOME/.goenv/bin:$PYENV_ROOT/bin:$PATH"
export PATH="$PATH:./node_modules/.bin"
export PATH="$PATH:/usr/local/opt/imagemagick@6/bin"
export PATH="$PATH:/Users/minamiyayuki/.local/bin" # pipx による追加

# ------------------------------
# 環境変数の設定
# ------------------------------
export GOENV_ROOT=$HOME/.goenv
export PYENV_ROOT="$HOME/.pyenv"
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=$(which chromium)
export LC_ALL=en_US.UTF-8

# ------------------------------
# anyenv / pyenv の初期化
# ------------------------------
eval "$(anyenv init -)"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# ------------------------------
# oh-my-zsh の設定
# ------------------------------
export ZSH=$HOME/src/github.com/yuki3738/dotfiles/oh-my-zsh
export ZSH_CUSTOM=${HOME}/src/github.com/yuki3738/dotfiles/.zsh.d
ZSH_THEME="fino"
plugins=(git ruby osx bundler rails themes)
source $ZSH/oh-my-zsh.sh

# ------------------------------
# GitHub の認証情報
# ------------------------------
GITHUB_CREDENTIAL_FILE=~/.github_credentials
if [ -e $GITHUB_CREDENTIAL_FILE ]; then
  source $GITHUB_CREDENTIAL_FILE
fi

# ------------------------------
# その他の設定
# ------------------------------
setopt nonomatch

# ------------------------------
# エイリアス
# ------------------------------
alias ssh='~/bin/ssh-change-profile.sh'
alias lg='lazygit'

# ------------------------------
# opam の設定
# ------------------------------
OPAM_INIT_FILE="$HOME/.opam/opam-init/init.zsh"
[ -r "$OPAM_INIT_FILE" ] && source "$OPAM_INIT_FILE" > /dev/null 2> /dev/null || true
