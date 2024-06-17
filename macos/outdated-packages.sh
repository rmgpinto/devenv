#!/bin/zsh -eo pipefail

function main() {
  mkdir -p ~/Library/LaunchAgents
  mkdir -p ~/.config/tmux/custom
  cat <<EOF > ~/Library/LaunchAgents/com.user.brewoutdatedpackages.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.user.brewoutdatedpackages</string>
    <key>ProgramArguments</key>
    <array>
      <string>/bin/bash</string>
      <string>-c</string>
      <string>/opt/homebrew/bin/brew update && /opt/homebrew/bin/brew outdated | wc -l | tr -d ' ' > ~/.config/tmux/custom/brew-outdated</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>11</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/brewoutdated.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/brewoutdated.log</string>
  </dict>
</plist>
EOF
  if ! launchctl list | grep -q "com.user.brewoutdatedpackages"; then
    launchctl load ~/Library/LaunchAgents/com.user.brewoutdatedpackages.plist
  else
    launchctl unload ~/Library/LaunchAgents/com.user.brewoutdatedpackages.plist
    launchctl load ~/Library/LaunchAgents/com.user.brewoutdatedpackages.plist
  fi

cat <<EOF > ~/Library/LaunchAgents/com.user.miseoutdatedpackages.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.user.miseoutdatedpackages</string>
    <key>ProgramArguments</key>
    <array>
      <string>/bin/bash</string>
      <string>-c</string>
      <string>/opt/homebrew/bin/mise plugins update && /opt/homebrew/bin/mise outdated | tail -n +2 | wc -l | tr -d ' ' > ~/.config/tmux/custom/mise-outdated</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>11</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/miseoutdated.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/miseoutdated.log</string>
  </dict>
</plist>
EOF
  if ! launchctl list | grep -q "com.user.miseoutdatedpackages"; then
    launchctl load ~/Library/LaunchAgents/com.user.miseoutdatedpackages.plist
  else
    launchctl unload ~/Library/LaunchAgents/com.user.miseoutdatedpackages.plist
    launchctl load ~/Library/LaunchAgents/com.user.miseoutdatedpackages.plist
  fi
}

main

