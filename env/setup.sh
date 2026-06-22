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
# nono reads its own keychain items at sandbox startup; -T must point at the
# binary that actually runs (mise's nono, behind the version-stable `latest`
# symlink that `command -v nono` resolves to).
NONO_BIN="$(command -v nono 2>/dev/null || mise which nono 2>/dev/null || true)"

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
# "${account}". nono reads these items itself, non-interactively, when it sets up
# the sandbox. Without a pre-authorized grant macOS pops an "Always Allow" dialog
# that nono can't answer, so the read fails (the credential is skipped); clicking
# it by hand doesn't stick either, since the per-app ACL grant is keyed to nono's
# code signature and gets wiped whenever it changes.
#
# -T grants nono's binary read access up front, so it never prompts. Because the
# grant is re-applied on every sync, recreating the item (delete + add) is fine —
# there's no hand-granted ACL to preserve. After a `mise upgrade` that changes
# nono's signature, re-run this script to refresh the grant. If nono can't be
# located we fall back to -A (any app) so the sync still completes.
function kc_add() {
  local service="$1" account="$2" value="$3"
  local -a trust
  if [[ -n "${NONO_BIN}" ]]; then
    trust=(-T "${NONO_BIN}")
  else
    log info "  nono not found on PATH; granting ${account} to any app (-A)"
    trust=(-A)
  fi
  "${SECURITY}" delete-generic-password -a "${account}" -s "${service}" >/dev/null 2>&1 || true
  "${SECURITY}" add-generic-password -a "${account}" -s "${service}" -w "${value}" "${trust[@]}"
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
