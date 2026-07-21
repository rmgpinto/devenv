# zsh
# Key bindings
bindkey "^[b" backward-word
bindkey "^[f" forward-word
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey -a -r '\e'  # Disable vi mode on shell prompt
bindkey -v -r '\e'  # Disable vi mode on shell prompt
bindkey -M emacs "^[[3~" delete-char
bindkey -M viins "^[[3~" delete-char

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
export XDG_CONFIG_HOME=${HOME}/.config
export EDITOR="nvim"

# mise
export MISE_LOG_LEVEL=warn
export MISE_TRUSTED_CONFIG_PATHS="${HOME}/dev"
eval "$(mise activate zsh)"

# worktrunk
if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

# zellij
FPATH="${XDG_CONFIG_HOME}/zellij/zsh:${FPATH}"
# Keep zellij's socket path short — macOS sun_path is 104 bytes and the default
# ${TMPDIR}/zellij-<uid>/contract_version_1/ already eats ~79 chars. Keep the
# uid suffix so per-user isolation matches zellij's default behavior.
export ZELLIJ_SOCKET_DIR=/tmp/zellij-$(id -u)

# starship
export STARSHIP_CONFIG="${XDG_CONFIG_HOME}/starship/starship.toml"
eval "$($HOME/.local/share/mise/installs/starship/latest/starship init zsh)"

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
source <($HOME/.local/share/mise/installs/fzf/latest/fzf --zsh)

# zoxide
eval "$($HOME/.local/share/mise/installs/zoxide/latest/zoxide init zsh)"

# gum
export GUM_CHOOSE_CURSOR_FOREGROUND="#cba6f7"
export GUM_CHOOSE_HEADER_FOREGROUND="#89b4fa"
export GUM_CHOOSE_SELECTED_FOREGROUND="#cba6f7"
export GUM_CHOOSE_ITEM_FOREGROUND="#cdd6f4"
export GUM_FILTER_INDICATOR_FOREGROUND="#a6e3a1"
export GUM_FILTER_MATCH_FOREGROUND="#f38ba8"
export GUM_FILTER_HEADER_FOREGROUND="#89b4fa"
export GUM_FILTER_PROMPT_FOREGROUND="#cba6f7"
export GUM_FILTER_TEXT_FOREGROUND="#cdd6f4"
export GUM_FILTER_CURSOR_TEXT_FOREGROUND="#f5e0dc"
export GUM_FILTER_PLACEHOLDER_FOREGROUND="#6c7086"
export GUM_INPUT_CURSOR_FOREGROUND="#cba6f7"
export GUM_INPUT_PROMPT_FOREGROUND="#89b4fa"
export GUM_INPUT_PLACEHOLDER_FOREGROUND="#6c7086"
export GUM_CONFIRM_PROMPT_FOREGROUND="#89b4fa"
export GUM_CONFIRM_SELECTED_FOREGROUND="#1e1e2e"
export GUM_CONFIRM_SELECTED_BACKGROUND="#cba6f7"
export GUM_CONFIRM_UNSELECTED_FOREGROUND="#cdd6f4"
export GUM_CONFIRM_UNSELECTED_BACKGROUND="#313244"
export GUM_SPIN_SPINNER_FOREGROUND="#fab387"
export GUM_SPIN_TITLE_FOREGROUND="#cdd6f4"

# yarn
PATH="${PATH}:${HOME}/.yarn/bin"

# gh enhance
export ENHANCE_THEME=catppuccin_mocha

# devenv scripts
PATH="${HOME}/dev/personal/devenv/bin:${PATH}"

# aliases
if [ -f ~/.zshaliases ]; then
  source ~/.zshaliases
fi

# zsh Completion
autoload -Uz compinit
compinit -C

