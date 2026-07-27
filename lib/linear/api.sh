#!/usr/bin/env bash

linear_require_api_key() {
  if [ -z "${LINEAR_API_KEY:-}" ]; then
    echo "linear: LINEAR_API_KEY is not set" >&2
    return 1
  fi
}

linear_graphql() {
  local query="$1"
  local variables="${2:-}"
  local response

  [ -n "$variables" ] || variables='{}'

  response=$(jq -nc --arg query "$query" --argjson variables "$variables" \
    '{query: $query, variables: $variables}' |
    curl -fsS -X POST https://api.linear.app/graphql \
      -H "Content-Type: application/json" \
      -H "Authorization: $LINEAR_API_KEY" \
      --data-binary @-) || return 1

  if [ "$(printf '%s' "$response" | jq -r '.errors | length // 0')" -ne 0 ]; then
    printf '%s' "$response" | jq -r '.errors[] | "linear: \(.message)"' >&2
    return 1
  fi

  printf '%s' "$response"
}
