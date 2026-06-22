#!/bin/zsh -eo pipefail

source "../utils/log.sh"

DEVENV_AI_DIR="$(cd "$(dirname "$0")" && pwd)"
SHARED_WORKSPACE="/Users/Shared/dev"
NONO_PROFILE="${HOME}/.config/nono/profiles/ai.json"

function setup_workspace() {
  log info "Stowing workspace agent files..."
  rm -f "${SHARED_WORKSPACE}/CLAUDE.md" "${SHARED_WORKSPACE}/AGENTS.md"
  ln -s personal/devenv/CLAUDE.md "${SHARED_WORKSPACE}/CLAUDE.md"
  ln -s CLAUDE.md "${SHARED_WORKSPACE}/AGENTS.md"
  log info "Done."
}

function setup_nono_profile() {
  log info "Installing nono profile..."
  mkdir -p "$(dirname "${NONO_PROFILE}")"
  local tmp
  tmp=$(mktemp)
  "${DEVENV_AI_DIR}/../env/render-ai-nono-profile.sh" \
    "${DEVENV_AI_DIR}/../env/ai.mise.toml" "${tmp}"
  install -m 0600 "${tmp}" "${NONO_PROFILE}"
  rm -f "${tmp}"
  log info "Done."
}

function setup_claude() {
  log info "Stowing Claude Code settings..."
  mkdir -p "${HOME}/.claude/themes"
  rm -f "${HOME}/.claude/settings.json" "${HOME}/.claude/themes/catppuccin-mocha.json"
  /opt/homebrew/bin/stow --no-folding -d "${DEVENV_AI_DIR}/dotfiles" claude -t "${HOME}"
  log info "Done."
}

function setup_codex() {
  log info "Stowing Codex CLI config..."
  mkdir -p "${HOME}/.codex"
  rm -f "${HOME}/.codex/config.toml"
  /opt/homebrew/bin/stow --no-folding -d "${DEVENV_AI_DIR}/dotfiles" codex -t "${HOME}"
  log info "Done."
}

function main() {
  setup_workspace
  setup_nono_profile
  setup_claude
  setup_codex
}

main

