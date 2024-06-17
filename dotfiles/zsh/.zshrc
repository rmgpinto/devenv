# zsh
# Key bindings
bindkey '\eOH' beginning-of-line
bindkey '\eOF' end-of-line
bindkey '^[[1;3C' forward-word
bindkey '^[[1;3D' backward-word
bindkey -a -r '\e'  # Disable vi mode
bindkey -v -r '\e'  # Disable vi mode


# Larger bash history (allow 32³ entries)
export HISTFILE=~/.zsh_history
export HISTSIZE=32768
export SAVEHIST=32768
export HISTFILESIZE=$HISTSIZE
export HISTCONTROL=ignoredups

# Syntax highlighting
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Auto suggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Completion
autoload -Uz compinit
compinit

# Environment variables
# Personal
export EDITOR="nvim"
# Work
export SAMMY_SSH_USER="ricardo"

# mise
export MISE_LOG_LEVEL=warn
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

# .dirrc
function source_dirrc() {
  # checking for tmux is necessary because it's not available in the first shell session, maybe because of the way mise works
  if [[ -f .dirrc && $(command -v tmux > /dev/null; echo $?) -eq 0 ]]; then
      source .dirrc
  fi
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd source_dirrc
source_dirrc

