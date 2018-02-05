setopt auto_cd
function chpwd() { ls }

# historyをpecoで検索
function peco-select-history() {
  BUFFER=$(fc -n -r -l 1 | peco --query "${LBUFFER}")
  CURSOR=${#BUFFER}
  zle clear-screen
}
zle -N peco-select-history
bindkey '^r' peco-select-history

# eでghqで入れたリポジトリをpeco検索する設定
function peco-src() {
  local dir=$(ghq list | peco)
  [[ -n ${dir} ]] && cd "${HOME}/src/${dir}"
}
alias e=peco-src
