#!/bin/zsh -eo pipefail

function main() {
  mkdir -p ~/Library/LaunchAgents/bin
  cd cron-scripts
  /opt/homebrew/bin/stow backup-git-ignored-work -t ${HOME}/Library/LaunchAgents
  cd ..
  launchctl unload ~/Library/LaunchAgents/com.user.backupgitignoredwork.plist > /dev/null
  launchctl load ~/Library/LaunchAgents/com.user.backupgitignoredwork.plist
}

main

