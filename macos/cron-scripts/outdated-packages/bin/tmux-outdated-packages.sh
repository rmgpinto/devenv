#!/bin/zsh -eo pipefail

function create_log_file() {
  if [ -f /tmp/tmuxoutdatedpackages.log ]; then
    echo "" > /tmp/tmuxoutdatedpackages.log
  fi
}

function main() {
  create_log_file
  PATH=$PATH:~/.local/share/mise/shims
  ~/.config/tmux/plugins/tpm/bin/update_plugins all
}

main

