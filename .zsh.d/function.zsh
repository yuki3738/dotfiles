# agvimの設定
function agvim () {
  vim $(ag $@ | peco --query "$LBUFFER" | awk -F : '{print "-c " $2 " " $1}')
}

# gimの設定
function gim() {
  local file=`git ls-files --cached | peco`
  [ -n "$file" ] && vim $file
}
