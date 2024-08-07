#!/bin/zsh -eo pipefail

function main() {
  # Screenshots
  mkdir -p ${HOME}/Screenshots
  defaults write com.apple.screencapture location ${HOME}/Screenshots

  # Dock apps
  defaults write com.apple.dock persistent-apps -array
  local dock_persistent_apps=(
    "/Applications/Alacritty.app"
    "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
    "/Applications/Notion.app"
    "/System/Applications/Notes.app"
    "/System/Applications/Mail.app"
    "/System/Applications/Calendar.app"
    "/Applications/Slack.app"
    "/System/Applications/Reminders.app"
    "/System/Applications/System%20Settings.app"
  )
  for dock_persistent_app in "${dock_persistent_apps[@]}"; do
      defaults write com.apple.dock persistent-apps -array-add \
      "<dict>
          <key>tile-data</key>
          <dict>
              <key>file-data</key>
              <dict>
                  <key>_CFURLString</key>
                  <string>file://${dock_persistent_app}</string>
                  <key>_CFURLStringType</key>
                  <integer>15</integer>
              </dict>
          </dict>
          <key>tile-type</key>
          <string>file-tile</string>
      </dict>"
  done

  defaults write com.apple.dock persistent-others -array
  local dock_persistent_others_directories=(
    "${HOME}/"
    "${HOME}/Screenshots/"
    "${HOME}/Downloads/"
  )
  for dock_persistent_others_directory in "${dock_persistent_others_directories[@]}"; do
    defaults write com.apple.dock persistent-others -array-add \
      "<dict>
          <key>tile-data</key>
          <dict>
              <key>file-data</key>
              <dict>
                  <key>_CFURLString</key>
                  <string>file://${dock_persistent_others_directory}</string>
                  <key>_CFURLStringType</key>
                  <integer>15</integer>
              </dict>
          </dict>
          <key>tile-type</key>
          <string>directory-tile</string>
      </dict>"
  done

  killall Dock
}

main

