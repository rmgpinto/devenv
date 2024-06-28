#!/bin/zsh -eo pipefail

function create_log_file() {
  if [ -f /tmp/miseoutdatedpackages.log ]; then
    echo "" > /tmp/miseoutdatedpackages.log
  fi
}

function main() {
  create_log_file
  /opt/homebrew/bin/mise plugins update && /opt/homebrew/bin/mise outdated | tail -n +2 | wc -l | tr -d ' ' > ~/.config/tmux/custom/mise-outdated
}

main

