#!/bin/zsh -eo pipefail

function main() {
  local mac_model=$(/usr/sbin/system_profiler SPHardwareDataType | awk -F': ' '/Model Name/ { print $2 }')
  local mac_chip=$(/usr/sbin/system_profiler SPHardwareDataType | awk -F ': ' '/Chip/ { print $2 }' | awk '{ print $2 }')
  local hostname=$(echo "${mac_model}" | tr -d ' ' | awk '{print tolower($1) $2}')
  local computername="${mac_model} ${mac_chip}"

  # Set the local hostname
  sudo scutil --set LocalHostName "${hostname}"

  # Set the computer name
  sudo scutil --set ComputerName "${computername}"

  # Set the host name
  sudo scutil --set HostName "${hostname}"
}

main

