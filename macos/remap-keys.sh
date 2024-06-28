#!/bin/zsh -eo pipefail

function main() {
  mkdir -p ~/Library/LaunchAgents/bin
  cd cron-scripts
  /opt/homebrew/bin/stow remap-capslock-to-control -t ${HOME}/Library/LaunchAgents
  cd ..
  launchctl unload ~/Library/LaunchAgents/com.user.remapcapslocktocontrol.plist > /dev/null
  launchctl load ~/Library/LaunchAgents/com.user.remapcapslocktocontrol.plist
}

main

