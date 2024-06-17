#!/bin/zsh -eo pipefail

function main() {
  mise settings set experimental true
  export TMUX_EXTRA_CONFIGURE_OPTIONS='--enable-utf8proc'
  [ -f packages ] && cat packages | grep -vE "^(#|$)" | xargs /opt/homebrew/bin/mise use -y -g
}

main

