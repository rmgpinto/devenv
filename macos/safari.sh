#!/bin/zsh -eo pipefail

function main() {
  # Show tab bar
  defaults write com.apple.Safari AlwaysShowTabBar -bool true
  # Show status bar
  defaults write com.apple.Safari ShowOverlayStatusBar -bool true
  # Show favourites bar
  defaults write com.apple.Safari "ShowFavoritesBar-v2" -bool true
  # Always restore session at launch
  defaults write com.apple.Safari AlwaysRestoreSessionAtLaunch -bool true
  # Show full URL
  defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
  # Search provider
  defaults write com.apple.Safari SearchProviderShortName "DuckDuckGo"
  # Disable autofill
  defaults write com.apple.Safari AutoFillPasswords -bool false
  defaults write com.apple.Safari AutoFillFromAddressBook -bool false
  defaults write com.apple.Safari AutoFillCreditCardData -bool false
  defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false
  # Enable the Develop menu and the Web Inspector in Safari
  defaults write com.apple.Safari IncludeDevelopMenu -bool true
  defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
  defaults write com.apple.Safari.SandboxBroker ShowDevelopMenu -bool true
}

main

