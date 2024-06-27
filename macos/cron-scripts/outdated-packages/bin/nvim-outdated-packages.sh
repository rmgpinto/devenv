#!/bin/zsh -eo pipefail

if [ -f /tmp/nvimoutdatedpackages.log ]; then
  echo "" > /tmp/nvimoutdatedpackages.log
fi

PATH=$PATH:~/.local/share/mise/shims
nvim --headless "+Lazy! sync" +qa
nvim --headless "+TSUpdateSync" +qa
nvim --headless "+MasonUpdateAll" +qa

