#!/bin/zsh -eo pipefail

if [ -f /tmp/tmuxoutdatedpackages.log ]; then
  echo "" > /tmp/tmuxoutdatedpackages.log
fi
PATH=$PATH:~/.local/share/mise/shims
~/.config/tmux/plugins/tpm/bin/update_plugins all

