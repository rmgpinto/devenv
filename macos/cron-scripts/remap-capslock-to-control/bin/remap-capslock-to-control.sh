#!/bin/zsh -eo pipefail

function create_log_file() {
  if [ -f /tmp/remap-capslock-to-control.log ]; then
    rm /tmp/remap-capslock-to-control.log
  fi
}

function main() {
  create_log_file
  hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}'
}

main

