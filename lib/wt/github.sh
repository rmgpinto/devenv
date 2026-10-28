#!/usr/bin/env bash

# Print the org's repos, most relevant first: repos you recently committed to,
# then the rest by last push. Cached; delete the cache file to refresh.
github_repos() {
  local org="$1"
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/wt"
  local cache="$cache_dir/repos.txt"
  local tmp
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

  if [ ! -s "$cache" ]; then
    tmp=$(mktemp -t wt-repos.XXXXXX)
    if gum spin --show-output --title "Loading GitHub repos" \
        -- bash -c _wt_fetch_github_repos >"$tmp" && [ -s "$tmp" ]; then
      mv "$tmp" "$cache"
    else
      rm -f "$tmp"
      return 0
    fi
  fi
  cat "$cache"
}

# Print open PRs in the org that request your review, one per line as
# "<repo>#<number> <title> — @<author>".
github_review_requests() {
  local org="$1"
  gum spin --show-output --title "Loading review requests" -- \
    gh search prs --review-requested=@me --state=open --owner "$org" \
      --limit 50 --json repository,number,title,author \
      --jq '.[] | "\(.repository.name)#\(.number) \(.title | gsub("[\\r\\n\\t]"; " ")) — @\(.author.login)"' \
    2>/dev/null || true
}

# Print a repo's open PRs, newest first, as "#<number> <title> — @<author>".
github_repo_prs() {
  local org="$1" repo="$2"
  gum spin --show-output --title "Loading $repo PRs" -- \
    gh pr list -R "$org/$repo" --state open --limit 50 --search 'sort:created-desc' \
      --json number,title,author \
      --jq '.[] | "#\(.number) \(.title | gsub("[\\r\\n\\t]"; " ")) — @\(.author.login)"' \
    2>/dev/null || true
}
