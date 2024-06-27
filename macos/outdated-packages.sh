#!/bin/zsh -eo pipefail

function main() {
  mkdir -p ~/Library/LaunchAgents/bin
  mkdir -p ~/.config/tmux/custom
  cd cron-scripts
  /opt/homebrew/bin/stow outdated-packages -t ${HOME}/Library/LaunchAgents
  cd ..
  if ! launchctl list | grep -q "com.user.brewoutdatedpackages"; then
    launchctl load ~/Library/LaunchAgents/com.user.brewoutdatedpackages.plist
  else
    launchctl unload ~/Library/LaunchAgents/com.user.brewoutdatedpackages.plist
    launchctl load ~/Library/LaunchAgents/com.user.brewoutdatedpackages.plist
  fi
  if ! launchctl list | grep -q "com.user.miseoutdatedpackages"; then
    launchctl load ~/Library/LaunchAgents/com.user.miseoutdatedpackages.plist
  else
    launchctl unload ~/Library/LaunchAgents/com.user.miseoutdatedpackages.plist
    launchctl load ~/Library/LaunchAgents/com.user.miseoutdatedpackages.plist
  fi
  if ! launchctl list | grep -q "com.user.tmuxoutdatedpackages"; then
    launchctl load ~/Library/LaunchAgents/com.user.tmuxoutdatedpackages.plist
  else
    launchctl unload ~/Library/LaunchAgents/com.user.tmuxoutdatedpackages.plist
    launchctl load ~/Library/LaunchAgents/com.user.tmuxoutdatedpackages.plist
  fi
  if ! launchctl list | grep -q "com.user.nvimoutdatedpackages"; then
    launchctl load ~/Library/LaunchAgents/com.user.nvimoutdatedpackages.plist
  else
    launchctl unload ~/Library/LaunchAgents/com.user.nvimoutdatedpackages.plist
    launchctl load ~/Library/LaunchAgents/com.user.nvimoutdatedpackages.plist
  fi
}

main

