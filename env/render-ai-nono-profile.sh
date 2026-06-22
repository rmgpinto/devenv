#!/bin/zsh -eo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 AI_SANDBOX_MISE_TOML OUTPUT_PROFILE" >&2
  exit 1
fi

input="$1"
output="$2"

yq -p toml -o json '.env // {}' "${input}" | jq '
  def keychain_service:
    if type == "string" then
      (capture("find-generic-password -s (?<service>[^ ]+) -w")? // {} | .service // null)
    else
      null
    end;

  def is_secret:
    keychain_service != null;

  {
    "$schema": "https://nono.sh/schemas/nono-profile.schema.json",
    "extends": "default",
    "meta": {
      "name": "ai",
      "version": "1.0.0",
      "description": "DevEnv AI profile generated from env/ai.mise.toml"
    },
    "workdir": {
      "access": "readwrite"
    },
    "filesystem": {
      "allow": [
        "$WORKDIR",
        "$HOME/.agents",
        "$HOME/.claude",
        "$HOME/.codex",
        "$HOME/.config/mise",
        "$HOME/.config/nono",
        "$HOME/.local/share/mise",
        "$HOME/.cache/mise",
        "$HOME/dev",
        "/tmp",
        "/private/tmp"
      ],
      "allow_file": [
        "$HOME/.claude.json"
      ],
      "read_file": [
        "/Users/Shared/dev/CLAUDE.md",
        "/Users/Shared/dev/AGENTS.md"
      ],
      "read": [
        "/bin",
        "/etc",
        "/opt",
        "/usr"
      ]
    },
    "network": {
      "block": false
    },
    "environment": {
      "allow_vars": [
        "PATH",
        "HOME",
        "USER",
        "LOGNAME",
        "SHELL",
        "TERM",
        "LANG",
        "LC_*",
        "TMPDIR",
        "MISE_*",
        "XDG_*"
      ],
      "set_vars": (
        to_entries
        | map(select(.value | is_secret | not))
        | from_entries
      )
    },
    "env_credentials": (
      to_entries
      | map(select(.value | is_secret) | {key: .key, value: .key})
      | from_entries
    )
  }
' > "${output}"
