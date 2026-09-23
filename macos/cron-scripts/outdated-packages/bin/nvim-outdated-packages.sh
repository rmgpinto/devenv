#!/bin/zsh -eo pipefail

function create_log_file() {
  if [ -f /tmp/nvimoutdatedpackages.log ]; then
    echo "" > /tmp/nvimoutdatedpackages.log
  fi
}

function main() {
  create_log_file
  /opt/homebrew/bin/mise exec -- nvim --headless "+Lazy! sync" +qa
  /opt/homebrew/bin/mise exec -- nvim --headless "+TSUpdateSync" +qa
  /opt/homebrew/bin/mise exec -- nvim --headless "+MasonUpdateAll" +qa
}

main
