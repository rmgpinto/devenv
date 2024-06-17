#/bin/zsh -eo pipefail

function main() {
  # Show all files
  defaults write com.apple.finder AppleShowAllFiles -bool true
  # Show all filename extensions
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  # Display full POSIX path as Finder window title
  defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
  # When performing a search, search the current folder by default
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
  # Disable the warning when changing a file extension
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
  # Use icon view in all Finder windows by default
  defaults write com.apple.finder FXPreferredViewStyle -string "icnv"
  # Show folders first
  defaults write com.apple.finder _FXSortFoldersFirst -bool true
  # Group by: None
  defaults write com.apple.finder FXPreferredGroupBy -string "None"
  # Sort by: Name
  defaults write com.apple.finder FXArrangeGroupViewBy -string "Name"
  # Standard View Settings for Icon View
  defaults write com.apple.finder StandardViewSettings -dict-add IconViewSettings '{
      arrangeBy = "grid";
      gridSpacing = 54;
      iconSize = 64;
      labelOnBottom = 1;
      showIconPreview = 1;
      showItemInfo = 1;
      textSize = 12;
      viewOptionsVersion = 1;
  }'
  # Show Path bar
  defaults write com.apple.finder ShowPathbar -bool true
  # Show Status bar
  defaults write com.apple.finder ShowStatusBar -bool true
  # Show home directory by default
  defaults write com.apple.finder NewWindowTargetPath -string "file://{$HOME}"
  # Hide recent tags
  defaults write com.apple.finder ShowRecentTags -bool false
  # Allow text selection in Quick Look
  defaults write com.apple.finder QLEnableTextSelection -bool true
  # Hide icons for hard drives, servers, and removable media on the desktop
  defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
  defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
  defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
  defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false
  # Avoid creating .DS_Store files on network volumes
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
}

main

