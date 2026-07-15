#!/usr/bin/env zsh

zellij_session_name_for() {
  local repo="$1"
  local branch="$2"
  local session

  branch=${branch//\//-}
  session="${repo}${branch:+-${branch}}"
  printf '%s' "${session:0:60}"
}

zellij_session_name_at() {
  local directory="${1:-$PWD}"
  local root repo branch

  root=$(/usr/bin/git -C "$directory" worktree list --porcelain 2>/dev/null | awk '/^worktree / {print $2; exit}')
  root=${root:-$directory}
  [ "$(basename "$(dirname "$root")")" = ".worktrees" ] && root=$(dirname "$(dirname "$root")")
  repo=$(basename "$root")
  branch=$(/usr/bin/git -C "$directory" rev-parse --abbrev-ref HEAD 2>/dev/null)
  [ "$branch" = HEAD ] && branch=

  zellij_session_name_for "$repo" "$branch"
}
