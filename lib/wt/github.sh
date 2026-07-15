#!/usr/bin/env bash

pick_github_repo() {
  local org="$1"
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/wt"
  local cache="$cache_dir/repos.txt"
  local refresh_label="Refresh Github repos"
  local repo_list repo tmp
  mkdir -p "$cache_dir"

  _wt_fetch_github_repos() {
    local recent active
    recent=$(gh search commits --author=@me --owner "$WT_GITHUB_ORG" \
      --sort committer-date --limit 100 --json repository \
      -q '.[].repository.name' 2>/dev/null || true)
    active=$(gh repo list "$WT_GITHUB_ORG" --limit 100 --json name,pushedAt \
      -q 'sort_by(.pushedAt) | reverse | .[].name')
    { printf '%s\n' "$recent"; printf '%s\n' "$active"; } |
      awk 'NF && !seen[$0]++'
  }
  export -f _wt_fetch_github_repos
  export WT_GITHUB_ORG="$org"

  while :; do
    if [ -s "$cache" ]; then
      repo_list=$(<"$cache")
    else
      tmp=$(mktemp -t wt-repos.XXXXXX)
      if gum spin --show-output --title "Refreshing Github repos" \
          -- bash -c _wt_fetch_github_repos >"$tmp" && [ -s "$tmp" ]; then
        mv "$tmp" "$cache"
        repo_list=$(<"$cache")
      else
        rm -f "$tmp"
        repo_list=""
      fi
    fi

    repo=$(printf '%s\n%s\n' "$refresh_label" "$repo_list" |
      gum filter --header "Pick a Github repo" --placeholder "type to filter")
    [ -n "$repo" ] || {
      echo "no Github repo picked" >&2
      return 1
    }
    if [ "$repo" = "$refresh_label" ]; then
      rm -f "$cache"
      continue
    fi

    printf '%s' "$repo"
    return
  done
}
