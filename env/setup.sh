#!/bin/zsh -eo pipefail

# Regenerate env: 1Password -> macOS keychain -> per-scope mise files.
#
# Run as the HOST user (needs `op` with biometric unlock). Reads env/secrets,
# pulls each value from 1Password, stores it in the host and/or ai-sandbox
# login keychain, then copies the *.mise.toml templates to their destinations.
# The mise files reference the keychain at load time, so no plaintext secret is
# ever written to disk.

# This script handles plaintext secrets in shell variables. Force xtrace/verbose
# OFF so a `set -x` / `setopt xtrace` inherited from ~/.zshenv (zsh sources it
# even for scripts) or a `zsh -x` invocation can never echo a secret value.
unsetopt xtrace verbose 2>/dev/null || set +x +v 2>/dev/null || true

source "../utils/log.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

SANDBOX_USER="ai-sandbox"
SANDBOX_GROUP="ai-sandbox"
SANDBOX_HOME="/Users/${SANDBOX_USER}"
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

function kc_add_ai_sandbox() {
  local service="$1" value="$2"
  sudo -H -u "${SANDBOX_USER}" "${SECURITY}" delete-generic-password \
    -a "${SANDBOX_USER}" -s "${service}" >/dev/null 2>&1 || true
  sudo -H -u "${SANDBOX_USER}" "${SECURITY}" add-generic-password \
    -a "${SANDBOX_USER}" -s "${service}" -w "${value}" -T "${SECURITY}"
}

function sync_secrets() {
  log info "Syncing secrets from 1Password to keychain..."

  # Declare the loop locals ONCE, here — never inside the loop. Re-running
  # `local service ref targets account value` each iteration re-declares
  # parameters that already exist in this scope, and zsh's typeset/local prints
  # an existing parameter as `name=value` to STDOUT. That leaks the previous
  # iteration's plaintext `value` (the secret) to the terminal on every
  # iteration after the first. (It's on stdout, not a trace — which is why an
  # xtrace guard or a 2>/dev/null redirect can't mute it.)
  local line service ref targets account value

  # Fixed-position fields at the ends; the op:// reference (which may contain
  # spaces, e.g. "GitHub PAT") is everything in between:
  #   service = $1, account = $NF, targets = $(NF-1), ref = $2..$(NF-2)
  #
  # Read from a process substitution (not `grep | while`) so the loop runs in
  # THIS shell and `exit 1` aborts the whole script, not just a pipe subshell.
  while IFS= read -r line; do
    service=$(awk '{print $1}' <<<"${line}")
    account=$(awk '{print $NF}' <<<"${line}")
    targets=$(awk '{print $(NF-1)}' <<<"${line}")
    ref=$(awk '{$1=""; $(NF-1)=""; $NF=""; sub(/^[[:space:]]+/,""); sub(/[[:space:]]+$/,""); print}' <<<"${line}")

    log info "  ${service} <- ${ref} [${targets}] (account: ${account})"

    if ! value=$(op read --account "${account}" "${ref}" 2>/dev/null); then
      log error "  failed to read ${ref} from 1Password account ${account}"
      exit 1
    fi

    case "${targets}" in
      main-user)  kc_add_main_user "${service}" "${value}" ;;
      ai-sandbox) kc_add_ai_sandbox "${service}" "${value}" ;;
      both)       kc_add_main_user "${service}" "${value}"; kc_add_ai_sandbox "${service}" "${value}" ;;
      *)          log error "  unknown target '${targets}' for ${service}"; exit 1 ;;
    esac
  done < <(grep -vE '^[[:space:]]*(#|$)' "${SECRETS_FILE}")
  log info "Done."
}

function write_mise_files() {
  log info "Writing per-scope mise files..."

  # Main-user-global: mise loads ~/.config/mise/conf.d/*.toml in every main-user
  # shell regardless of cwd, so these vars are available at the workspace root
  # too. Main-user-only (ai-sandbox has its own home and never reads this).
  mkdir -p "${HOME}/.config/mise/conf.d"
  install -m 0644 "${SCRIPT_DIR}/main-user.mise.toml" "${HOME}/.config/mise/conf.d/devenv.toml"

  # Main user, dir-scoped. Owned by the main user, world-readable is fine: the
  # files contain keychain *lookups*, not secrets (and ai-sandbox can't read the
  # main user's keychain even if it reads the file).
  install -m 0644 "${SCRIPT_DIR}/work.mise.toml"     "${SHARED_WORKSPACE}/work/.mise.toml"
  install -m 0644 "${SCRIPT_DIR}/personal.mise.toml" "${SHARED_WORKSPACE}/personal/.mise.toml"

  # ai-sandbox global config, owned by ai-sandbox, private.
  sudo -u "${SANDBOX_USER}" mkdir -p "${SANDBOX_HOME}/.config/mise"
  sudo install -o "${SANDBOX_USER}" -g "${SANDBOX_GROUP}" -m 0600 \
    "${SCRIPT_DIR}/ai-sandbox.mise.toml" "${SANDBOX_HOME}/.config/mise/config.toml"

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
