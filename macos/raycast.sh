#!/bin/zsh -eo pipefail

function main() {
  # Disable Spotlight default key bindings
  /usr/libexec/PlistBuddy ${HOME}/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Delete AppleSymbolicHotKeys:64' || true
  /usr/libexec/PlistBuddy ${HOME}/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:64:enabled bool false' || true
  /usr/libexec/PlistBuddy ${HOME}/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Delete AppleSymbolicHotKeys:65' || true
  /usr/libexec/PlistBuddy ${HOME}/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:65:enabled bool false' || true
  # Set <Command-Space> as Raycast key binding
  defaults write com.raycast.macos raycastGlobalHotkey -string "Command-49"
}

main

