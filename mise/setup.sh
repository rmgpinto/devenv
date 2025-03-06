#!/bin/zsh -eo pipefail

function main() {
  mise settings set experimental true
  mise plugins add zjstatus https://github.com/rmgpinto/asdf-zjstatus.git
  mise plugins add docker https://github.com/rmgpinto/asdf-docker.git
  mise plugins add docker-buildx https://github.com/rmgpinto/asdf-docker-buildx.git
  mise plugins add docker-compose https://github.com/rmgpinto/asdf-docker-compose.git
  [ -f packages ] && cat packages | sed 's/#.*//' | sed '/^\s*$/d' | xargs /opt/homebrew/bin/mise use -y -g
}

main

