function git_status() {
  if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) = 'true' ]]; then
    echo
    echo "--- git status ---"
    git status -sb

    # stash list
    stash=$(git stash list)
    if [[ -n $stash ]]; then
      echo
      echo "--- git stash ---"
      echo $stash
    fi
  fi
}

function dir_status() {
  if [[ -n $BUFFER ]]; then
    zle accept-line
    return 0
  fi

  echo
  ls
  git_status
  echo
  echo

  zle reset-prompt
}
zle -N dir_status
bindkey '^m' dir_status
