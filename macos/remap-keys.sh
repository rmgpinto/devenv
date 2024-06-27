#!/bin/zsh -eo pipefail

function main() {
  mkdir -p ~/Library/LaunchAgents/bin
  cd cron-scripts
  /opt/homebrew/bin/stow remap-capslock-to-control -t ${HOME}/Library/LaunchAgents
  cd ..
  if ! launchctl list | grep -q "com.user.remapcapslocktocontrol"; then
    launchctl load ~/Library/LaunchAgents/com.user.remapcapslocktocontrol.plist
  else
    launchctl unload ~/Library/LaunchAgents/com.user.remapcapslocktocontrol.plist
    launchctl load ~/Library/LaunchAgents/com.user.remapcapslocktocontrol.plist
  fi
}

main

