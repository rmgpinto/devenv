#!/bin/zsh -eo pipefail

if [ -f /tmp/miseoutdatedpackages.log ]; then
  echo "" > /tmp/miseoutdatedpackages.log
fi
/opt/homebrew/bin/mise plugins update && /opt/homebrew/bin/mise outdated | tail -n +2 | wc -l | tr -d ' ' > ~/.config/tmux/custom/mise-outdated

