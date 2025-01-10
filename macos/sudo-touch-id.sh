#!/bin/zsh -eo pipefail

function main() {
  sudo tee /etc/pam.d/sudo_local >/dev/null <<EOF
# Enable TouchID for sudo
auth       sufficient     pam_tid.so
EOF
}

main

