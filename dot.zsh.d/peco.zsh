function peco-src() {
  local dir=$(ghq list | peco)
  [[ -n ${dir} ]] && cd "${HOME}/.ghq/${dir}"
}
alias e=peco-src
