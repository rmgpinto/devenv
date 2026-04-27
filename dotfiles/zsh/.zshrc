# zsh
# Key bindings
bindkey "^[b" backward-word
bindkey "^[f" forward-word
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey -a -r '\e'  # Disable vi mode on shell prompt
bindkey -v -r '\e'  # Disable vi mode on shell prompt

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
export HAL_1P_ACCOUNT_ID="GHXJDH3PVNHG3PLWLS5RT4HOHI"
export HAL_1P_STAGING="op://Employee/Ghost - staging"
export HAL_1P_PRODUCTION="op://Employee/Ghost - production"

# mise
export MISE_LOG_LEVEL=warn
eval "$(mise activate zsh)"

# zellij
FPATH="${XDG_CONFIG_HOME}/zellij/zsh:${FPATH}"

# starship
export STARSHIP_CONFIG="${XDG_CONFIG_HOME}/starship/starship.toml"
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

# yarn
PATH="${PATH}:${HOME}/.yarn/bin"

# devenv scripts
PATH="/Users/Shared/dev/personal/devenv/bin:${PATH}"

# gum (Catppuccin Mocha)
export GUM_CHOOSE_CURSOR_FOREGROUND="#cba6f7"   # Mauve
export GUM_CHOOSE_HEADER_FOREGROUND="#89b4fa"   # Blue
export GUM_CHOOSE_SELECTED_FOREGROUND="#cba6f7" # Mauve
export GUM_FILTER_INDICATOR_FOREGROUND="#a6e3a1" # Green
export GUM_FILTER_MATCH_FOREGROUND="#f38ba8"     # Red
export GUM_INPUT_CURSOR_FOREGROUND="#cba6f7"    # Mauve
export GUM_INPUT_PROMPT_FOREGROUND="#89b4fa"    # Blue
export GUM_SPIN_SPINNER_FOREGROUND="#fab387"    # Peach

# aliases
if [ -f ~/.zshaliases ]; then
  source ~/.zshaliases
fi

# zsh Completion
autoload -Uz compinit
compinit

