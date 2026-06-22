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
  [ -f cask_packages ] && cat cask_packages | grep -vE "^(#|$)" | sed 's/#.*//' | sed '/^\s*$/d' | xargs /opt/homebrew/bin/brew install --cask -y
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
  brew outdated --cask --greedy
  brew upgrade -y
  brew upgrade --cask --greedy -y
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
