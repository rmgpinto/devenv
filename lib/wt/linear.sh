#!/usr/bin/env bash

pick_linear_issue_description() {
  [ -n "${LINEAR_API_KEY:-}" ] || return 0

  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/wt"
  local cache="$cache_dir/linear.json"
  local refresh_label="Refresh Linear issues"
  local response display selection issue_id rc tmp
  mkdir -p "$cache_dir"

  _wt_fetch_linear_issues() {
    local query='query { viewer { assignedIssues(filter: {state: {name: {in: ["Todo", "In Progress", "Ready"]}}}, first: 100, orderBy: updatedAt) { nodes { identifier title description state { name } } } } }'
    jq -nc --arg q "$query" '{query: $q}' |
      curl -fsS -X POST https://api.linear.app/graphql \
        -H "Content-Type: application/json" \
        -H "Authorization: $LINEAR_API_KEY" \
        --data-binary @-
  }
  export -f _wt_fetch_linear_issues
  export LINEAR_API_KEY

  while :; do
    if [ -s "$cache" ]; then
      response=$(<"$cache")
    else
      tmp=$(mktemp -t wt-linear.XXXXXX)
      if gum spin --show-output --title "Loading Linear issues" \
          -- bash -c _wt_fetch_linear_issues >"$tmp" && [ -s "$tmp" ]; then
        mv "$tmp" "$cache"
        response=$(<"$cache")
      else
        rm -f "$tmp"
        response=""
      fi
    fi

    display=$(printf '%s' "$response" | jq -r '
      .data.viewer.assignedIssues.nodes // []
      | sort_by(.identifier | split("-") | [.[0], (.[1] | tonumber)])
      | .[] | "[\(.identifier)] \(.title) — \(.state.name)"
    ' 2>/dev/null || true)

    rc=0
    selection=$(printf '%s\n%s\n' "$refresh_label" "$display" |
      gum filter --header "Pick a Linear issue (esc to skip)" \
        --placeholder "type to filter") || rc=$?
    [ "$rc" -ge 130 ] && return "$rc"

    if [ "$selection" = "$refresh_label" ]; then
      rm -f "$cache"
      continue
    fi
    [ -n "$selection" ] || return 0

    issue_id=$(printf '%s' "$selection" | sed 's/^\[\([^]]*\)\].*/\1/')
    printf '%s' "$response" | jq -r --arg id "$issue_id" '
      .data.viewer.assignedIssues.nodes[]
      | select(.identifier == $id)
      | .description // ""
    '
    return
  done
}
