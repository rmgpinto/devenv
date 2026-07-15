#!/usr/bin/env bash

set_worktrunk_return_directory() {
  local target="$1"

  if [ -n "${WORKTRUNK_DIRECTIVE_EXEC_FILE:-}" ]; then
    printf 'local -a _wt_saved_chpwd_functions\n' >"$WORKTRUNK_DIRECTIVE_EXEC_FILE"
    printf '_wt_saved_chpwd_functions=("${chpwd_functions[@]}")\n' >>"$WORKTRUNK_DIRECTIVE_EXEC_FILE"
    printf 'chpwd_functions=()\n' >>"$WORKTRUNK_DIRECTIVE_EXEC_FILE"
    printf 'builtin cd -- %q\n' "$target" >>"$WORKTRUNK_DIRECTIVE_EXEC_FILE"
    printf 'eval "$(/opt/homebrew/bin/mise --no-hooks hook-env -s zsh --reason chpwd)"\n' >>"$WORKTRUNK_DIRECTIVE_EXEC_FILE"
    printf 'export __MISE_ZSH_CHPWD_RAN=1\n' >>"$WORKTRUNK_DIRECTIVE_EXEC_FILE"
    printf 'chpwd_functions=("${_wt_saved_chpwd_functions[@]}")\n' >>"$WORKTRUNK_DIRECTIVE_EXEC_FILE"
  elif [ -n "${WORKTRUNK_DIRECTIVE_CD_FILE:-}" ]; then
    printf '%s\n' "$target" >"$WORKTRUNK_DIRECTIVE_CD_FILE"
  fi
}
