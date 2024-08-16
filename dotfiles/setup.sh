#!/bin/zsh -eo pipefail

source "../utils/log.sh"

function setup_alacritty() {
  log info "Setting up alacritty..."
  curl -s -L -o alacritty/.config/alacritty/catppuccin-mocha.toml https://github.com/catppuccin/alacritty/raw/main/catppuccin-mocha.toml
  /opt/homebrew/bin/stow alacritty -t ${HOME}
  log info "Done."
}

function setup_zsh() {
  log info "Setting up zsh..."
  /opt/homebrew/bin/stow zsh -t ${HOME}
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
  /opt/homebrew/bin/stow starship -t ${HOME}
  log info "Done."
}

function setup_hushlogin() {
  log info "Setting up hushlogin..."
  /opt/homebrew/bin/stow hushlogin -t ${HOME}
  log info "Done."
}

function setup_git() {
  log info "Setting up git..."
  mkdir -p ${HOME}/.config/git/hooks
  /opt/homebrew/bin/stow git -t ${HOME}
  log info "Done."
}

function setup_gh() {
  log info "Setting up gh..."
  sudo gh completion -s zsh | sudo tee /usr/local/share/zsh/site-functions/_gh > /dev/null
  /opt/homebrew/bin/stow gh -t ${HOME}
  log info "Done."
}

function setup_lazygit() {
  log info "Setting up lazygit..."
  /opt/homebrew/bin/stow lazygit -t ${HOME}
  log info "Done."
}

function setup_ssh() {
  log info "Setting up ssh..."
  log info "Done."
  /opt/homebrew/bin/stow ssh -t ${HOME}
}

function setup_tmux() {
  log info "Setting up tmux..."
  mkdir -p ~/.config/tmux/plugins/tpm
  if [[ ! -f ~/.config/tmux/plugins/tpm/tpm ]]; then
    git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
  fi  
  /opt/homebrew/bin/stow tmux -t ${HOME}
  log info "Done."
}

function setup_tmuxinator() {
  log info "Setting up tmuxinator..."
  if ! command -v tmuxinator &> /dev/null; then
    sudo gem install tmuxinator
    sudo curl -o /usr/local/share/zsh/site-functions/_tmuxinator https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.zsh
  fi
  /opt/homebrew/bin/stow tmuxinator -t ${HOME}
  log info "Done."
}

function setup_neovim() {
  log info "Setting up neovim..."
  /opt/homebrew/bin/stow nvim -t ${HOME}
  log info "Done."
}

function setup_bat() {
  log info "Setting up bat..."
  curl -s -L -o bat/.config/bat/themes/catppuccin-mocha.tmTheme "https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme"
  /opt/homebrew/bin/stow bat -t ${HOME}
  bat cache --build > /dev/null
  log info "Done."
}

function setup_bundle() {
  log info "Setting up bundle..."
  /opt/homebrew/bin/stow bundle -t ${HOME}
  log info "Done."
}

function setup_docker() {
  log info "Setting up docker..."
  docker completion zsh | sudo tee /usr/local/share/zsh/site-functions/_docker > /dev/null
  ln -s $(brew --prefix)/lib/docker/cli-plugins ~/.docker/cli-plugins
  log info "Done."
}

function setup_ghost() {
  log info "Setting up Ghost Toolbox..."
  ORIGINAL_DIR=$(pwd)
  TOOLBOX_DIR=~/dev/work/Toolbox
  if [[ -d ${TOOLBOX_DIR} ]]; then
    cd ${TOOLBOX_DIR}/stow
    ./stow.sh
  else
    log error "Toolbox not found in ~/dev/work."
  fi
  cd ${ORIGINAL_DIR}
  log info "Done."
  log info "Setting up Ghost kubectl..."
  mkdir -p ~/.kube
  stow kubernetes -t ${HOME}/dev/work
  log info "Done."
  log info "Setting up Ghost k9s..."
  stow k9s -t ${HOME}
  log info "Done."
}

function main() {
  setup_alacritty
  setup_zsh
  setup_mise
  setup_starship
  setup_hushlogin
  setup_git
  setup_gh
  setup_lazygit
  setup_ssh
  setup_tmux
  setup_tmuxinator
  setup_neovim
  setup_bat
  setup_bundle
  setup_docker
  setup_ghost
}

main

