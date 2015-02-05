# zの設定
. /usr/local/etc/profile.d/z.sh
function _Z_precmd {
  z --add "$(pwd -P)" 61
}
precmd_functions=($precmd_functions _Z_precmd)

