#!/bin/zsh -eo pipefail

function create_log_file() {
  if [ -f /tmp/nvimoutdatedpackages.log ]; then
    echo "" > /tmp/nvimoutdatedpackages.log
  fi
}

function main() {
  create_log_file
  PATH=$PATH:~/.local/share/mise/shims
  nvim --headless "+Lazy! sync" +qa
  nvim --headless "+TSUpdateSync" +qa
  nvim --headless "+MasonUpdateAll" +qa
}

main

