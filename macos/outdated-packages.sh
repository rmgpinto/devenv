#!/bin/zsh -eo pipefail

function main() {
  mkdir -p ~/Library/LaunchAgents/bin
  cd cron-scripts
  /opt/homebrew/bin/stow outdated-packages -t ${HOME}/Library/LaunchAgents
  cd ..
  launchctl unload ~/Library/LaunchAgents/com.user.brewoutdatedpackages.plist > /dev/null
  launchctl load ~/Library/LaunchAgents/com.user.brewoutdatedpackages.plist
  launchctl unload ~/Library/LaunchAgents/com.user.miseoutdatedpackages.plist > /dev/null
  launchctl load ~/Library/LaunchAgents/com.user.miseoutdatedpackages.plist
  launchctl unload ~/Library/LaunchAgents/com.user.nvimoutdatedpackages.plist > /dev/null
  launchctl load ~/Library/LaunchAgents/com.user.nvimoutdatedpackages.plist
}

main

