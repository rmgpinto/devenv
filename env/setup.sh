#!/bin/zsh -eo pipefail

# Regenerate env: 1Password -> macOS keychain -> per-scope mise/nono files.
#
# Run as the HOST user (needs `op` with biometric unlock). Reads env/secrets,
# pulls each value from 1Password, stores it in the host login keychain, then
# copies the *.mise.toml templates to their destinations and renders the nono
# AI profile. The mise/nono files reference the keychain at load time, so no
# plaintext secret is ever written to disk.

# This script handles plaintext secrets in shell variables. Force xtrace/verbose
# OFF so a `set -x` / `setopt xtrace` inherited from ~/.zshenv (zsh sources it
# even for scripts) or a `zsh -x` invocation can never echo a secret value.
unsetopt xtrace verbose 2>/dev/null || set +x +v 2>/dev/null || true

source "../utils/log.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

SHARED_WORKSPACE="/Users/Shared/dev"
SECURITY="/usr/bin/security"
SECRETS_FILE="${SCRIPT_DIR}/secrets"
NONO_PROFILE="${HOME}/.config/nono/profiles/ai.json"

function require_op() {
  if ! command -v op >/dev/null 2>&1; then
    log error "1Password CLI (op) not found. Install it (mise/packages: 1password-cli) and retry."
    exit 1
  fi
  # No global `op signin`: secrets may live in different accounts, so each read
  # passes --account and 1Password unlocks on demand (enable the desktop app's
  # "Connect with 1Password CLI" / Touch ID integration to avoid prompts).
  # Just verify at least one account is configured up front.
  if ! op account list >/dev/null 2>&1; then
    log error "No 1Password accounts configured. Run: op account add --address <addr> --signin"
    exit 1
  fi
}

# Store a secret in a keychain. We delete any existing item first, then add a
# fresh one, so stale attributes/ACLs from a prior sync don't linger (-U would
# update the value in place but keep the old item). -T /usr/bin/security lets
# `security find-generic-password` read it back without an interactive prompt
# (mise's exec template calls exactly that).
function kc_add_main_user() {
  local service="$1" value="$2"
  "${SECURITY}" delete-generic-password -a "${USER}" -s "${service}" >/dev/null 2>&1 || true
  "${SECURITY}" add-generic-password -a "${USER}" -s "${service}" \
    -w "${value}" -T "${SECURITY}"
}

function kc_add_nono() {
  local account="$1" value="$2"
  "${SECURITY}" delete-generic-password \
    -a "${account}" -s nono >/dev/null 2>&1 || true
  "${SECURITY}" add-generic-password \
    -a "${account}" -s nono -w "${value}" -T "${SECURITY}"
}

function sync_secrets() {
  log info "Syncing secrets from 1Password to keychain..."

  # Declare the loop locals ONCE, here — never inside the loop. Re-running
  # `local service ref account value` each iteration re-declares
  # parameters that already exist in this scope, and zsh's typeset/local prints
  # an existing parameter as `name=value` to STDOUT. That leaks the previous
  # iteration's plaintext `value` (the secret) to the terminal on every
  # iteration after the first. (It's on stdout, not a trace — which is why an
  # xtrace guard or a 2>/dev/null redirect can't mute it.)
  local line service ref account value

  # Fixed-position fields at the ends; the op:// reference (which may contain
  # spaces, e.g. "GitHub PAT") is everything in between:
  #   service = $1, account = $NF, ref = $2..$(NF-1)
  #
  # Read from a process substitution (not `grep | while`) so the loop runs in
  # THIS shell and `exit 1` aborts the whole script, not just a pipe subshell.
  while IFS= read -r line; do
    service=$(awk '{print $1}' <<<"${line}")
    account=$(awk '{print $NF}' <<<"${line}")
    ref=$(awk '{$1=""; $NF=""; sub(/^[[:space:]]+/,""); sub(/[[:space:]]+$/,""); print}' <<<"${line}")

    log info "  ${service} <- ${ref} (account: ${account})"

    if ! value=$(op read --account "${account}" "${ref}" 2>/dev/null); then
      log error "  failed to read ${ref} from 1Password account ${account}"
      exit 1
    fi

    kc_add_main_user "${service}" "${value}"
  done < <(grep -vE '^[[:space:]]*(#|$)' "${SECRETS_FILE}")
  log info "Done."
}

function sync_nono_ai_env_credentials() {
  log info "Syncing AI mise env secrets to host nono keychain entries..."

  local env_name service value
  while read -r env_name service; do
    if ! value=$("${SECURITY}" find-generic-password \
      -a "${USER}" -s "${service}" -w 2>/dev/null); then
      log error "  missing host keychain service '${service}' for ${env_name}"
      exit 1
    fi
    kc_add_nono "${env_name}" "${value}"
  done < <(
    yq -p toml -o json '.env // {}' "${SCRIPT_DIR}/ai.mise.toml" \
      | jq -r 'to_entries[]
          | select(.value | type == "string")
          | (.value | capture("find-generic-password -s (?<service>[^ ]+) -w").service?) as $service
          | select($service != null)
          | [.key, $service] | @tsv'
  )

  log info "Done."
}

function write_mise_files() {
  log info "Writing per-scope mise files..."

  # User-global: mise loads ~/.config/mise/conf.d/*.toml in every shell
  # regardless of cwd, so these vars are available at the workspace root too.
  mkdir -p "${HOME}/.config/mise/conf.d"
  install -m 0644 "${SCRIPT_DIR}/user.mise.toml" "${HOME}/.config/mise/conf.d/devenv.toml"

  # Dir-scoped. These files contain keychain lookups, not secrets.
  [[ -f "${SCRIPT_DIR}/work.mise.toml" ]] \
    && install -m 0644 "${SCRIPT_DIR}/work.mise.toml" "${SHARED_WORKSPACE}/work/.mise.toml"
  [[ -f "${SCRIPT_DIR}/personal.mise.toml" ]] \
    && install -m 0644 "${SCRIPT_DIR}/personal.mise.toml" "${SHARED_WORKSPACE}/personal/.mise.toml"

  mkdir -p "$(dirname "${NONO_PROFILE}")"
  local tmp
  tmp=$(mktemp)
  "${SCRIPT_DIR}/render-ai-nono-profile.sh" "${SCRIPT_DIR}/ai.mise.toml" "${tmp}"
  install -m 0600 "${tmp}" "${NONO_PROFILE}"
  rm -f "${tmp}"

  log info "Done."
}

function main() {
  log info "Setting up env..."
  require_op
  sync_secrets
  sync_nono_ai_env_credentials
  write_mise_files
  log info "Done."
}

main "$@"
