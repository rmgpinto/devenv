#!/bin/zsh -eo pipefail

function main() {
  # Screenshots
  mkdir -p ${HOME}/Screenshots

  # Dock apps
  defaults write com.apple.dock persistent-apps -array
  DOCK_PERSISTENT_APPS=(
    "/Applications/Alacritty.app"
    "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
    "/Applications/Obsidian.app"
    "/Applications/Notion.app"
    "/System/Applications/Mail.app"
    "/System/Applications/Calendar.app"
    "/Applications/Slack.app"
    "/System/Applications/Reminders.app"
    "/System/Applications/System%20Settings.app"
  )
  for DOCK_PERSISTENT_APP in "${DOCK_PERSISTENT_APPS[@]}"; do
      defaults write com.apple.dock persistent-apps -array-add \
      "<dict>
          <key>tile-data</key>
          <dict>
              <key>file-data</key>
              <dict>
                  <key>_CFURLString</key>
                  <string>file://${DOCK_PERSISTENT_APP}</string>
                  <key>_CFURLStringType</key>
                  <integer>15</integer>
              </dict>
          </dict>
          <key>tile-type</key>
          <string>file-tile</string>
      </dict>"
  done

  defaults write com.apple.dock persistent-others -array
  DOCK_PERSISTENT_OTHERS_DIRECTORIES=(
    "${HOME}/"
    "${HOME}/Screenshots/"
    "${HOME}/Downloads/"
  )
  for DOCK_PERSISTENT_OTHERS_DIRECTORY in "${DOCK_PERSISTENT_OTHERS_DIRECTORIES[@]}"; do
    defaults write com.apple.dock persistent-others -array-add \
      "<dict>
          <key>tile-data</key>
          <dict>
              <key>file-data</key>
              <dict>
                  <key>_CFURLString</key>
                  <string>file://${DOCK_PERSISTENT_OTHERS_DIRECTORY}</string>
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

