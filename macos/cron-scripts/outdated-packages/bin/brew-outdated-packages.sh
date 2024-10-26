#!/bin/zsh -eo pipefail

function create_log_file() {
  if [ -f /tmp/brewoutdatedpackages.log ]; then
    echo "" > /tmp/brewoutdatedpackages.log
  fi
}

function main() {
  create_log_file
  /opt/homebrew/bin/brew update --cask
}

main

