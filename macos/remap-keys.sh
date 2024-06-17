#!/bin/zsh -eo pipefail

function main() {
  mkdir -p ~/Library/LaunchAgents
  cat <<EOF > ~/Library/LaunchAgents/com.user.remapcapslock.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.user.remapcapslock</string>
    <key>ProgramArguments</key>
    <array>
      <string>/usr/bin/hidutil</string>
      <string>property</string>
      <string>--set</string>
      <string>{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
  </dict>
</plist>
EOF
  if ! launchctl list | grep -q "com.user.remapcapslock"; then
    launchctl load ~/Library/LaunchAgents/com.user.remapcapslock.plist
  else
    launchctl unload ~/Library/LaunchAgents/com.user.remapcapslock.plist
    launchctl load ~/Library/LaunchAgents/com.user.remapcapslock.plist
  fi
}

main

