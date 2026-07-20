#!/bin/zsh -eo pipefail

source "../utils/log.sh"

DEV_WORKSPACE="${DEV_WORKSPACE:-${HOME}/dev}"

function setup_workspace() {
  log info "Setting up workspace agent files..."
  mkdir -p "${DEV_WORKSPACE}"
  rm -f "${DEV_WORKSPACE}/CLAUDE.md" "${DEV_WORKSPACE}/AGENTS.md"
  ln -s personal/devenv/CLAUDE.md "${DEV_WORKSPACE}/CLAUDE.md"
  ln -s CLAUDE.md "${DEV_WORKSPACE}/AGENTS.md"
  log info "Done."
}

function setup_ghostty() {
  log info "Setting up ghostty..."
  /opt/homebrew/bin/stow --adopt ghostty -t ${HOME}
  log info "Done."
}

function setup_zsh() {
  log info "Setting up zsh..."
  /opt/homebrew/bin/stow --adopt zsh -t ${HOME}
  log info "Done".
}

function setup_mise() {
  log info "Setting up mise..."
  /opt/homebrew/bin/mise use -g usage
  sudo mkdir -p /usr/local/share/zsh/site-functions
  mise completion zsh | sudo tee /usr/local/share/zsh/site-functions/_mise > /dev/null
  log info "Done."
}

function setup_starship() {
  log info "Setting up starship..."
  curl -s -L -o starship/.config/starship/catppuccin-mocha.toml https://raw.githubusercontent.com/catppuccin/starship/main/themes/mocha.toml
  /opt/homebrew/bin/stow --adopt starship -t ${HOME}
  log info "Done."
}

function setup_hushlogin() {
  log info "Setting up hushlogin..."
  /opt/homebrew/bin/stow --adopt hushlogin -t ${HOME}
  log info "Done."
}

function setup_git() {
  log info "Setting up git..."
  mkdir -p ${HOME}/.config/git/hooks
  /opt/homebrew/bin/stow --adopt git -t ${HOME}
  if [[ ! -f ${HOME}/.gitconfig ]]; then
    ln -s ${HOME}/.config/git/config ~/.gitconfig # this is necessary for TryGhost/Ghost
  fi
  log info "Done."
}

function setup_gh() {
  log info "Setting up gh..."
  gh_latest_source="${DEV_WORKSPACE}/personal/devenv/dotfiles/gh/.config/gh/gh-latest"
  gh_latest_target="${HOME}/.local/share/mise/installs/github-cli/latest/gh-latest"
  if [[ -x "${gh_latest_source}" && -d "${gh_latest_target:h}" ]]; then
    ln -sfn "${gh_latest_source}" "${gh_latest_target}"
    "${gh_latest_target}" completion -s zsh | sudo tee /usr/local/share/zsh/site-functions/_gh > /dev/null
  else
    log error "Unable to link gh-latest into mise github-cli latest install"
  fi
  /opt/homebrew/bin/stow --adopt gh -t ${HOME}
  log info "Done."
}

function setup_lazygit() {
  log info "Setting up lazygit..."
  /opt/homebrew/bin/stow --adopt lazygit -t ${HOME}
  log info "Done."
}

function setup_worktrunk() {
  log info "Setting up Worktrunk..."
  /opt/homebrew/bin/stow --adopt worktrunk -t ${HOME}
  /opt/homebrew/bin/mise exec aqua:max-sixty/worktrunk -- wt config shell install --yes zsh
  log info "Done."
}

function setup_ssh() {
  log info "Setting up ssh..."
  log info "Done."
  /opt/homebrew/bin/stow --adopt ssh -t ${HOME}
}

function setup_zellij() {
  log info "Setting up zellij..."
  local zellij_repo="${DEV_WORKSPACE}/personal/zellij"
  local zellij_bin="${zellij_repo}/target/release/zellij"
  local agent_plugin_dir="${DEV_WORKSPACE}/personal/devenv/plugins/zellij-agent-status"
  local wasi_sdk_version="33.0"
  local wasi_sdk_dir="${agent_plugin_dir}/.cache/wasi-sdk-${wasi_sdk_version}-arm64-macos"
  local upstream

  if [[ ! -d "${zellij_repo}/.git" ]]; then
    log error "Zellij repo not found at ${zellij_repo}"
    return 1
  fi

  if [[ "$(/usr/bin/git -C "${zellij_repo}" branch --show-current)" != "main" ]]; then
    log error "Zellij repo is not on main; skipping sync/build"
    return 1
  fi

  if [[ -z "$(/usr/bin/git -C "${zellij_repo}" status --porcelain)" ]]; then
    if /usr/bin/git -C "${zellij_repo}" remote get-url upstream >/dev/null 2>&1; then
      upstream="upstream/main"
    else
      upstream="origin/main"
    fi
    if /usr/bin/git -C "${zellij_repo}" fetch --all --prune; then
      if ! /usr/bin/git -C "${zellij_repo}" merge --no-edit "${upstream}"; then
        /usr/bin/git -C "${zellij_repo}" merge --abort >/dev/null 2>&1 || true
        log error "Zellij main conflicts with ${upstream}; merge aborted"
      fi
    else
      log error "Unable to fetch Zellij remotes; continuing with local checkout"
    fi
  else
    log error "Zellij repo has local changes; skipping sync to avoid clobbering them"
  fi

  (cd "${zellij_repo}" && cargo build --release --bin zellij)
  if [[ ! -x "${wasi_sdk_dir}/bin/clang" ]]; then
    local wasi_sdk_archive="${agent_plugin_dir}/.cache/wasi-sdk-${wasi_sdk_version}-arm64-macos.tar.gz"
    mkdir -p "${agent_plugin_dir}/.cache"
    curl -fsSL \
      "https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${wasi_sdk_version%%.*}/wasi-sdk-${wasi_sdk_version}-arm64-macos.tar.gz" \
      -o "${wasi_sdk_archive}"
    tar -xzf "${wasi_sdk_archive}" -C "${agent_plugin_dir}/.cache"
    rm -f "${wasi_sdk_archive}"
  fi
  (
    cd "${agent_plugin_dir}"
    RUSTC_BOOTSTRAP=1 \
      CARGO_TARGET_WASM32_WASIP1_LINKER="${wasi_sdk_dir}/bin/clang" \
      CARGO_TARGET_WASM32_WASIP1_RUSTFLAGS="-C linker-flavor=gcc -C link-self-contained=no -C link-arg=-Wl,--export=load -C link-arg=-Wl,--export=update -C link-arg=-Wl,--export=render -C link-arg=-Wl,--export=pipe -C link-arg=-Wl,--export=plugin_version" \
      cargo build -Z build-std=std,panic_abort --release
  )
  mkdir -p zellij/.config/zellij/zsh
  "${zellij_bin}" setup --generate-completion zsh > zellij/.config/zellij/zsh/_zellij
  /opt/homebrew/bin/stow --adopt zellij -t ${HOME}
  log info "Done."
}

function setup_neovim() {
  log info "Setting up neovim..."
  /opt/homebrew/bin/stow --adopt nvim -t ${HOME}
  log info "Done."
}

function setup_bat() {
  log info "Setting up bat..."
  curl -s -L -o bat/.config/bat/themes/catppuccin-mocha.tmTheme "https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme"
  /opt/homebrew/bin/stow --adopt bat -t ${HOME}
  bat cache --build > /dev/null
  log info "Done."
}

function setup_bundle() {
  log info "Setting up bundle..."
  /opt/homebrew/bin/stow --adopt bundle -t ${HOME}
  log info "Done."
}

function setup_docker() {
  log info "Setting up docker..."
  docker completion zsh | sudo tee /usr/local/share/zsh/site-functions/_docker > /dev/null
  log info "Done."
}

function setup_nono() {
  log info "Setting up nono profile..."
  mkdir -p "${HOME}/.config/nono/profiles"
  /opt/homebrew/bin/stow --adopt --no-folding nono -t "${HOME}"
  log info "Done."
}

function setup_claude() {
  log info "Setting up Claude Code settings..."
  mkdir -p "${HOME}/.config/claude/themes"
  /opt/homebrew/bin/stow --adopt --no-folding claude -t "${HOME}"
  log info "Done."
}

function setup_codex() {
  log info "Setting up Codex CLI config..."
  mkdir -p "${HOME}/.config/codex"
  /opt/homebrew/bin/stow --adopt --no-folding codex -t "${HOME}"
  log info "Done."
}

function setup_ghost() {
  log info "Setting up Ghost Toolbox..."
  ORIGINAL_DIR=$(pwd)
  TOOLBOX_DIR="${DEV_WORKSPACE}/work/Toolbox"
  if [[ -d ${TOOLBOX_DIR} ]]; then
    cd ${TOOLBOX_DIR}/stow
    ./stow.sh
  else
    log error "Toolbox not found in ${DEV_WORKSPACE}/work."
  fi
  cd ${ORIGINAL_DIR}
  log info "Done."
  log info "Setting up Ghost kubectl..."
  mkdir -p ~/.kube
  log info "Done."
  log info "Setting up Ghost k9s..."
  stow --adopt k9s -t ${HOME}
  log info "Done."
  log info "Setting up Ghost HAL..."
  ORIGINAL_DIR=$(pwd)
  HAL_DIR="${DEV_WORKSPACE}/work/HAL"
  if [[ -d ${HAL_DIR} ]]; then
    cd ${HAL_DIR}
    /opt/homebrew/bin/mise trust
    /opt/homebrew/bin/mise install
    /opt/homebrew/bin/mise exec -- yarn
    /opt/homebrew/bin/mise exec -- yarn unlink 2>/dev/null || true
    /opt/homebrew/bin/mise exec -- yarn link
  else
    log error "HAL not found in ${DEV_WORKSPACE}/work."
  fi
  cd ${ORIGINAL_DIR}
  log info "Done."
}

function main() {
  setup_workspace
  setup_ghostty
  setup_zsh
  setup_mise
  setup_starship
  setup_hushlogin
  setup_git
  setup_gh
  setup_lazygit
  setup_worktrunk
  setup_ssh
  setup_zellij
  setup_neovim
  setup_bat
  setup_bundle
  setup_docker
  setup_nono
  setup_claude
  setup_codex
  setup_ghost
}

main
