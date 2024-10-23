#!/bin/zsh -eo pipefail

function main() {
  mise settings set experimental true
  mise plugins add docker https://github.com/rmgpinto/asdf-docker.git
  mise plugins add docker-compose https://github.com/rmgpinto/asdf-docker-compose.git
  export TMUX_EXTRA_CONFIGURE_OPTIONS='--enable-utf8proc'
  [ -f packages ] && cat packages | grep -vE "^(#|$)" | xargs /opt/homebrew/bin/mise use -y -g
}

main

