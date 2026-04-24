#!/bin/zsh -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

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
    (cd macos && ./setup.sh)
    log info "Done."
  fi
}

function brew() {
  if [[ -f "brew/setup.sh" ]]; then
    log info "Setting up brew..."
    (cd brew && ./setup.sh)
    log info "Done."
  fi
}

function dotfiles() {
  if [[ -f "dotfiles/setup.sh" ]]; then
    log info "Setting up dotfiles..."
    (cd dotfiles && ./setup.sh)
    log info "Done."
  fi
}

function mise() {
  if [[ -f "mise/setup.sh" ]]; then
    log info "Setting up mise..."
    (cd mise && ./setup.sh)
    log info "Done."
  fi
}

function ai() {
  if [[ -f "ai/setup.sh" ]]; then
    log info "Setting up ai..."
    (cd ai && ./setup.sh)
    log info Done.
  fi
}

function main() {
  log info "Setting up devenv..."
  rosetta
  macos
  brew
  mise
  dotfiles
  ai
  log info "Done."
}


main "$@"

