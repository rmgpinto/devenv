#!/bin/zsh -eo pipefail

if [ -f /tmp/remap-capslock-to-control.log ]; then
  rm /tmp/remap-capslock-to-control.log
fi
hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}'

