#!/bin/zsh -eo pipefail

function main() {
  mise settings set experimental true
  mise plugins add zjstatus https://github.com/rmgpinto/asdf-zjstatus.git
  [ -f packages ] && cat packages | sed 's/#.*//' | sed '/^\s*$/d' | xargs /opt/homebrew/bin/mise use -y -g
  mise plugins update
  mise outdated
  mise upgrade
  mise prune -y
}

main

