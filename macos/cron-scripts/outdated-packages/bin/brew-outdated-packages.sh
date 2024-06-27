#!/bin/zsh -eo pipefail

if [ -f /tmp/brewoutdatedpackages.log ]; then
  echo "" > /tmp/brewoutdatedpackages.log
fi
/opt/homebrew/bin/brew update && /opt/homebrew/bin/brew outdated | wc -l | tr -d ' ' > ~/.config/tmux/custom/brew-outdated

