#!/bin/zsh -eo pipefail

source "../utils/log.sh"

export HOMEBREW_NO_ASK=1

function install_brew() {
  if [ ! -f "/opt/homebrew/bin/brew" ]; then
    log info "Installing brew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    log info "Done."
  fi
}

function install_brew_packages() {
  log info "Installing brew packages..."
  [ -f packages ] && cat packages | grep -vE "^(#|$)" | sed 's/#.*//' | sed '/^\s*$/d' | xargs /opt/homebrew/bin/brew install -y
  log info "Done."
}

function install_brew_cask_packages() {
  log info "Installing brew cask packages..."
  if [[ -f cask_packages ]]; then
    sed 's/#.*//' cask_packages | sed '/^[[:space:]]*$/d' | while read -r cask; do
      /opt/homebrew/bin/brew list --cask "$cask" >/dev/null 2>&1 ||
        /opt/homebrew/bin/brew install --cask -y "$cask"
    done
  fi
  log info "Done."
}

function install_brew_mas_packages() {
  log info "Installing brew mas packages..."
  [ -f mas_packages ] && cat mas_packages | grep -vE "^(#|$)" | sed 's/#.*//' | sed '/^\s*$/d' | xargs /opt/homebrew/bin/mas install
  log info "Done."
}

function upgrade_brew_packages() {
  log info "Upgrading brew packages..."
  brew update --force
  brew outdated --cask
  brew upgrade -y
  brew upgrade --cask -y
  brew cleanup
  log info "Done."
}

function main() {
  install_brew
  /opt/homebrew/bin/brew update --force
  install_brew_packages
  install_brew_cask_packages
  install_brew_mas_packages
  upgrade_brew_packages
}

main
