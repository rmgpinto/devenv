#!/bin/zsh -eo pipefail

function create_log_file() {
  if [ -f /tmp/brewoutdatedpackages.log ]; then
    echo "" > /tmp/brewoutdatedpackages.log
  fi
}

function main() {
  create_log_file
  /opt/homebrew/bin/brew update --cask
  OUTDATED_PACKAGES=$(/opt/homebrew/bin/brew outdated | wc -l | tr -d ' ')
  OUTDATED_CASK_PACKAGES=$(/opt/homebrew/bin/brew outdated --cask --greedy | wc -l | tr -d ' ')
  echo $((OUTDATED_PACKAGES + OUTDATED_CASK_PACKAGES)) > ~/.config/tmux/custom/brew-outdated
}

main

