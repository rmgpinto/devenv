#!/bin/zsh -eo pipefail

function main() {
  # Disable the sound effects on boot
  sudo nvram SystemAudioVolume=%80
  sudo nvram StartupMute=%01

  # Network
  # Firewall
  sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1
  sudo defaults write /Library/Preferences/com.apple.alf allowsignedenabled -int 1
  sudo defaults write /Library/Preferences/com.apple.alf allowdownloadsignedenabled -int 1

  # Sound
  # Alert volume 50%
  defaults write NSGlobalDomain com.apple.sound.beep.volume -float 0.6065307
  # Disable play user interface sounds effects
  defaults write NSGlobalDomain com.apple.sound.uiaudio.enabled -int 0

  # General
  # Language & Region
  # First day of Week
  defaults write NSGlobalDomain AppleFirstWeekday -dict gregorian 2
  # Number format
  defaults write NSGlobalDomain AppleICUNumberSymbols -dict 0 '.'
  defaults write NSGlobalDomain AppleICUNumberSymbols -dict 1 ','
  defaults write NSGlobalDomain AppleICUNumberSymbols -dict 10 ','
  defaults write NSGlobalDomain AppleICUNumberSymbols -dict 17 ','

  # Appearance
  # Dark Mode
  defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

  # Control Center
  # Menu Bar icons
  # Bluetooth
  defaults write ~/Library/Preferences/ByHost/com.apple.controlcenter.plist Bluetooth -int 18
  # Sound
  defaults write ~/Library/Preferences/ByHost/com.apple.controlcenter.plist Sound -int 16
  # Battery
  defaults write ~/Library/Preferences/ByHost/com.apple.controlcenter.plist BatteryShowPercentage -int 1
  # Clock
  defaults write com.apple.menuextra.clock DateFormat -string "\"EEE d MMM HH:mm:ss\""
  defaults write com.apple.menuextra.clock ShowSeconds -bool true
  # Spotlight
  defaults -currentHost write com.apple.Spotlight MenuItemHidden -int 1
  # Keyboard
  defaults write com.apple.TextInputMenu visible -int 0


  # Desktop & Dock
  # Icon size of Dock: 48 pixels
  defaults write com.apple.dock tilesize -int 48
  # Auto-hide Dock
  defaults write com.apple.dock autohide -bool true
  # Don't show recent applications in Dock
  defaults write com.apple.dock show-recents -bool false
  # Disable Hot Corners
  defaults write com.apple.dock wvous-tl-corner -int 1
  defaults write com.apple.dock wvous-tr-corner -int 1
  defaults write com.apple.dock wvous-bl-corner -int 1
  defaults write com.apple.dock wvous-br-corner -int 1
  # Disable automatically arranje spaces based on most recent use
  defaults write com.apple.dock mru-spaces -bool false
  # Disable tiled windows margins
  defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false

  # Wallpaper
  WALLPAPER_PATH="/System/Library/Desktop Pictures/Solid Colors/Black.png"
  osascript -e "tell application \"System Events\" to set picture of every desktop to \"${WALLPAPER_PATH}\" as POSIX file"

  # Screen saver
  # Start never
  defaults -currentHost write com.apple.screensaver idleTime -int 0
  # Ask for password immediately after sleep
  defaults -currentHost write com.apple.screensaver askForPassword -bool true
  defaults -currentHost write com.apple.screensaver askForPasswordDelay -int 0
  # Keyboard
  # Key repeat rate
  defaults write NSGlobalDomain KeyRepeat -int 1
  # Delay until repeat
  defaults write NSGlobalDomain InitialKeyRepeat -int 14
  # Disable spell check
  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticTextCompletionEnabled -bool false
  # Enable long press
  defaults write -g ApplePressAndHoldEnabled -bool true
  # Shortcuts
  # Disable Mission Control shortcuts
  for key in 32 34 79 80; do
    /usr/libexec/PlistBuddy -c 'Delete AppleSymbolicHotKeys:'${key} ${HOME}/Library/Preferences/com.apple.symbolichotkeys.plist || true
    /usr/libexec/PlistBuddy -c 'Add AppleSymbolicHotKeys:'${key}':enabled bool false' ${HOME}/Library/Preferences/com.apple.symbolichotkeys.plist || true
  done
  # Trackpad
  # Tracking speed
  defaults write NSGlobalDomain com.apple.trackpad.scaling 2.5
  # Tap to click
  defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -bool true
  # Disable swipe between pages
  defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool false
}

main

