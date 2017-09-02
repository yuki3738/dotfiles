setopt auto_cd
function chpwd() { ls }

# agvimの設定
function agvim () {
  vim $(ag $@ | peco --query "$LBUFFER" | awk -F : '{print "-c " $2 " " $1}')
}

# gimの設定
function gim() {
  local file=`git ls-files --cached | peco`
  [ -n "$file" ] && vim $file
}

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
