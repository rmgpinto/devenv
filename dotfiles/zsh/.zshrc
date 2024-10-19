# zsh
# Key bindings
bindkey '\eOH' beginning-of-line
bindkey '\eOF' end-of-line
bindkey '^[[1;3C' forward-word
bindkey '^[[1;3D' backward-word
bindkey -a -r '\e'  # Disable vi mode
bindkey -v -r '\e'  # Disable vi mode

# History
export HISTFILE=~/.zsh_history
export HISTSIZE=32768
export SAVEHIST=32768
export HISTFILESIZE=$HISTSIZE
export HISTCONTROL=ignoredups
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# Syntax highlighting
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Auto suggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Environment variables
# Common
export XDG_CONFIG_HOME=${HOME}/.config
# Personal
export EDITOR="nvim"
# Work
export SAMMY_SSH_USER="ricardo"

# mise
export MISE_LOG_LEVEL=warn
export MISE_TRUSTED_CONFIG_PATHS="${HOME}/dev"
eval "$(mise activate zsh)"

# starship
export STARSHIP_CONFIG="${HOME}/.config/starship/starship.toml"
eval "$(~/.local/share/mise/shims/starship init zsh)"

# homebrew
if type brew &>/dev/null
then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

# bat
export BAT_THEME="catppuccin-mocha"

# fzf
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
export FZF_CTRL_R_OPTS="
  --preview 'echo {}' --preview-window up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic"
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
source <(~/.local/share/mise/shims/fzf --zsh)

# zoxide
eval "$(~/.local/share/mise/shims/zoxide init zsh)"

# aliases
if [ -f ~/.zshaliases ]; then
  source ~/.zshaliases
fi

# tmuxinator auto-layout
function run_mise_tmuxinator() {
  # checking for tmux is necessary because it's not available in the first shell session, maybe because of the way mise works
  if [[ $(command -v tmux > /dev/null; echo $?) -eq 0 ]]; then
    MISE_TMUXINATOR_FILE=$(find . -maxdepth 1 -name ".mise*.toml" -print -quit)
    if [[ -n "${MISE_TMUXINATOR_FILE}" ]] && [[ -z "$TMUX" ]]; then
      if [[ "$(yq '.tasks.tmuxinator' ${MISE_TMUXINATOR_FILE} 2> /dev/null)" != "null" ]]; then
        mise run tmuxinator
      fi
    fi
  fi
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd run_mise_tmuxinator
run_mise_tmuxinator

# zsh Completion
autoload -Uz compinit
compinit

