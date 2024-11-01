#!/bin/zsh -eo pipefail

function main() {
  sudo tee /etc/pam.d/sudo_local >/dev/null <<EOF
# Enable TouchID for sudo
auth       optional       /opt/homebrew/Cellar/pam-reattach/1.3/lib/pam/pam_reattach.so ignore_ssh
# Enable TouchID for sudo
auth       sufficient     pam_tid.so
EOF
}

main

