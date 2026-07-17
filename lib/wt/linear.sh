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
    if [ -n "${WT_LINEAR_ISSUE_FILE:-}" ]; then
      printf '%s\n' "$issue_id" > "$WT_LINEAR_ISSUE_FILE"
    fi
    printf '%s' "$response" | jq -r --arg id "$issue_id" '
      .data.viewer.assignedIssues.nodes[]
      | select(.identifier == $id)
      | .description // ""
    '
    return
  done
}

mark_linear_issue_in_progress() {
  local issue_identifier="$1"
  local query response issue_id state_id label_id label_ids mutation

  [ -n "${LINEAR_API_KEY:-}" ] && [ -n "$issue_identifier" ] || return 1

  query='query IssueAutomationContext($issueId: String!) {
    issue(id: $issueId) {
      id
      labels { nodes { id } }
      team { states { nodes { id name } } }
    }
    issueLabels(filter: {name: {eq: "Agent-assisted"}}, first: 50) {
      nodes { id name parent { name } }
    }
  }'
  response=$(jq -nc --arg q "$query" --arg issueId "$issue_identifier" \
    '{query: $q, variables: {issueId: $issueId}}' \
    | curl -fsS -X POST https://api.linear.app/graphql \
        -H "Content-Type: application/json" \
        -H "Authorization: $LINEAR_API_KEY" \
        --data-binary @-) || return 1

  [ "$(printf '%s' "$response" | jq -r '.errors | length // 0')" -eq 0 ] || return 1
  issue_id=$(printf '%s' "$response" | jq -r '.data.issue.id // empty')
  state_id=$(printf '%s' "$response" | jq -r \
    '.data.issue.team.states.nodes[] | select(.name == "In Progress") | .id' | head -1)
  label_id=$(printf '%s' "$response" | jq -r \
    '.data.issueLabels.nodes[] | select(.name == "Agent-assisted" and .parent.name == "Bots") | .id' \
    | head -1)
  [ -n "$issue_id" ] && [ -n "$state_id" ] && [ -n "$label_id" ] || return 1

  label_ids=$(printf '%s' "$response" | jq -c --arg label "$label_id" \
    '[.data.issue.labels.nodes[].id, $label] | unique')
  mutation='mutation StartIssue($issueId: String!, $stateId: String!, $labelIds: [String!]!) {
    issueUpdate(id: $issueId, input: {stateId: $stateId, labelIds: $labelIds}) {
      success
    }
  }'
  response=$(jq -nc \
    --arg q "$mutation" \
    --arg issueId "$issue_id" \
    --arg stateId "$state_id" \
    --argjson labelIds "$label_ids" \
    '{query: $q, variables: {issueId: $issueId, stateId: $stateId, labelIds: $labelIds}}' \
    | curl -fsS -X POST https://api.linear.app/graphql \
        -H "Content-Type: application/json" \
        -H "Authorization: $LINEAR_API_KEY" \
        --data-binary @-) || return 1

  [ "$(printf '%s' "$response" | jq -r '.data.issueUpdate.success // false')" = "true" ]
}
