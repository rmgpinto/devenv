#!/bin/zsh -eo pipefail

source "utils/log.sh"

function rosetta() {
  if ! /usr/bin/pgrep oahd >/dev/null 2>&1; then
    log info "Setting rosetta..."
    softwareupdate --install-rosetta --agree-to-license
    log info "Done."
  fi
}

function macos() {
  if [[ -f "macos/setup.sh" ]]; then
    log info "Setting up Mac OS..."
    cd macos && ./setup.sh && cd ..
    log info "Done."
  fi
}

function brew() {
  if [[ -f "brew/setup.sh" ]]; then
    log info "Setting up brew..."
    cd brew && ./setup.sh && cd ..
    log info "Done."
  fi
}

function dotfiles() {
  if [[ -f "dotfiles/setup.sh" ]]; then
    log info "Setting up dotfiles..."
    cd dotfiles && ./setup.sh && cd ..
    log info "Done."
  fi
}

function mise() {
  if [[ -f "mise/setup.sh" ]]; then
    log info "Setting up mise..."
    cd mise && ./setup.sh && cd ..
    log info "Done."
  fi
}

function main() {
  log info "Setting up devenv..."
  rosetta
  macos
  brew
  mise
  dotfiles
  log info "Done."
}


main "$@"

