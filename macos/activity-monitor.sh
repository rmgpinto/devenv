#!/bin/zsh -eo pipefail

function main() {
  # Show the main window when launching Activity Monitor
  defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
  # Show all processes in Activity Monitor
  defaults write com.apple.ActivityMonitor ShowCategory -int 0
  # Sort Activity Monitor results by CPU usage
  defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
  defaults write com.apple.ActivityMonitor SortDirection -int 0 
}

main

