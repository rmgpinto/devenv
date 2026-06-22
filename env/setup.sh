#!/bin/zsh -eo pipefail

# Regenerate env: 1Password -> macOS keychain -> per-scope mise files.
#
# Run as the HOST user (needs `op` with biometric unlock). Reads env/secrets,
# pulls each value from 1Password, stores it in the host login keychain, then
# copies the *.mise.toml templates to their destinations. The mise files and the
# nono AI profile (env_credentials) reference the keychain at load time, so no
# plaintext secret is ever written to disk. The nono profile itself is stowed by
# dotfiles/setup.sh; this script only populates the keychain accounts it reads.

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

# Cache a secret in the login keychain under service "${service}", account
# "${account}". Delete any existing item first, then add a fresh one, so stale
# attributes/ACLs from a prior sync don't linger (-U would update the value in
# place but keep the old item).
#
# -A makes the item readable by any local process without an interactive prompt.
# We can't pin trust to the readers instead: nono is an ad-hoc/linker-signed,
# per-version binary (mise installs each release under a new path with a new
# cdhash), so a "-T <nono>" / "Always Allow" grant never survives an upgrade and
# macOS re-prompts. The values are handed to the sandboxed agent as env vars
# anyway, so -A doesn't widen the exposure on this host.
function kc_add() {
  local service="$1" account="$2" value="$3"
  "${SECURITY}" delete-generic-password -a "${account}" -s "${service}" >/dev/null 2>&1 || true
  "${SECURITY}" add-generic-password -a "${account}" -s "${service}" -w "${value}" -A
}

function sync_secrets() {
  log info "Syncing secrets from 1Password to keychain..."

  # Declare the loop locals ONCE, here — never inside the loop. Re-running
  # `local store name ref account value` each iteration re-declares
  # parameters that already exist in this scope, and zsh's typeset/local prints
  # an existing parameter as `name=value` to STDOUT. That leaks the previous
  # iteration's plaintext `value` (the secret) to the terminal on every
  # iteration after the first. (It's on stdout, not a trace — which is why an
  # xtrace guard or a 2>/dev/null redirect can't mute it.)
  local line store name ref account value

  # Fixed-position fields at the ends; the op:// reference (which may contain
  # spaces, e.g. "GitHub PAT") is everything in between:
  #   store = $1, name = $2, account = $NF, ref = $3..$(NF-1)
  #
  # Read from a process substitution (not `grep | while`) so the loop runs in
  # THIS shell and `exit 1` aborts the whole script, not just a pipe subshell.
  while IFS= read -r line; do
    store=$(awk '{print $1}' <<<"${line}")
    name=$(awk '{print $2}' <<<"${line}")
    account=$(awk '{print $NF}' <<<"${line}")
    ref=$(awk '{$1=""; $2=""; $NF=""; sub(/^[[:space:]]+/,""); sub(/[[:space:]]+$/,""); print}' <<<"${line}")

    log info "  ${store}-${name} <- ${ref} (account: ${account})"

    if ! value=$(op read --account "${account}" "${ref}" 2>/dev/null); then
      log error "  failed to read ${ref} from 1Password account ${account}"
      exit 1
    fi

    kc_add "${store}" "${store}-${name}" "${value}"
  done < <(grep -vE '^[[:space:]]*(#|$)' "${SECRETS_FILE}")
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

  log info "Done."
}

function main() {
  log info "Setting up env..."
  require_op
  sync_secrets
  write_mise_files
  log info "Done."
}

main "$@"
