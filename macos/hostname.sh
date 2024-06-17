#!/bin/zsh -eo pipefail

function main() {
  MAC_MODEL=$(/usr/sbin/system_profiler SPHardwareDataType | awk -F': ' '/Model Name/ { print $2 }')
  MAC_CHIP=$(/usr/sbin/system_profiler SPHardwareDataType | awk -F ': ' '/Chip/ { print $2 }' | awk '{ print $2 }')
  HOSTNAME=$(echo "${MAC_MODEL}" | tr -d ' ' | awk '{print tolower($1) $2}')
  COMPUTERNAME="${MAC_MODEL} ${MAC_CHIP}"

  # Set the local hostname
  sudo scutil --set LocalHostName "${HOSTNAME}"

  # Set the computer name
  sudo scutil --set ComputerName "${COMPUTERNAME}"

  # Set the host name
  sudo scutil --set HostName "${HOSTNAME}"
}

main

