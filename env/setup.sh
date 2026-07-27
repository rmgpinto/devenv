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

DEV_WORKSPACE="${DEV_WORKSPACE:-${HOME}/dev}"
SECURITY="/usr/bin/security"
SECRETS_FILE="${SCRIPT_DIR}/secrets"
# nono reads its own keychain items at sandbox startup; -T must point at the real
# binary that runs. Resolve it via mise's absolute path — this script runs
# non-interactively (no mise shell activation), so `command -v nono` would miss
# it or return a shim, and -T on a shim wouldn't match the real reader.
NONO_BIN="$(/opt/homebrew/bin/mise which nono 2>/dev/null || command -v nono 2>/dev/null || true)"
NONO_SIGNING_IDENTITY="DevEnv Nono"
NONO_SIGNING_IDENTIFIER="dev.rmgpinto.nono"
NONO_ACL_REFRESH="${HOME}/.local/state/devenv/refresh-nono-keychain-acl"
NONO_ACL_CONFIGURED="${HOME}/.local/state/devenv/nono-codesign-acl-v1"
if [[ -e "${NONO_ACL_REFRESH}" ]]; then
  REFRESH_NONO_KEYCHAIN_ACL=1
else
  REFRESH_NONO_KEYCHAIN_ACL="${REFRESH_NONO_KEYCHAIN_ACL:-0}"
fi

function create_nono_signing_identity() (
  unsetopt xtrace verbose 2>/dev/null || true

  local keychain="${HOME}/Library/Keychains/login.keychain-db"
  local temporary
  local private_key certificate bundle passphrase
  temporary="$(mktemp -d -t devenv-nono-codesign.XXXXXX)"
  private_key="${temporary}/nono.key"
  certificate="${temporary}/nono.crt"
  bundle="${temporary}/nono.p12"
  trap '/bin/rm -f -- "${private_key}" "${certificate}" "${bundle}"; /bin/rmdir "${temporary}" 2>/dev/null || true' EXIT

  passphrase="$(openssl rand -hex 32)"
  openssl req -new -newkey rsa:3072 -x509 -sha256 -days 3650 -nodes \
    -subj "/CN=${NONO_SIGNING_IDENTITY}" \
    -addext "basicConstraints=critical,CA:FALSE" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=codeSigning" \
    -keyout "${private_key}" \
    -out "${certificate}" >/dev/null 2>&1
  openssl pkcs12 -export \
    -legacy \
    -name "${NONO_SIGNING_IDENTITY}" \
    -inkey "${private_key}" \
    -in "${certificate}" \
    -passout "pass:${passphrase}" \
    -out "${bundle}"
  "${SECURITY}" import "${bundle}" \
    -k "${keychain}" \
    -P "${passphrase}" \
    -T /usr/bin/codesign \
    -T "${SECURITY}" >/dev/null
)

function sign_nono() {
  local keychain="${HOME}/Library/Keychains/login.keychain-db"
  local needs_acl_refresh=false

  [[ -n "${NONO_BIN}" && -x "${NONO_BIN}" ]] || return 0

  if ! "${SECURITY}" find-certificate \
      -c "${NONO_SIGNING_IDENTITY}" "${keychain}" >/dev/null 2>&1; then
    log info "Creating stable local Nono code-signing identity..."
    create_nono_signing_identity
    needs_acl_refresh=true
  fi

  if [[ ! -e "${NONO_ACL_CONFIGURED}" ]]; then
    needs_acl_refresh=true
  fi

  log info "Signing Nono with stable local identity..."
  /usr/bin/codesign --force \
    --sign "${NONO_SIGNING_IDENTITY}" \
    --identifier "${NONO_SIGNING_IDENTIFIER}" \
    --timestamp=none \
    "${NONO_BIN}"
  /usr/bin/codesign --verify --strict "${NONO_BIN}"

  if [[ "${needs_acl_refresh}" == true ]]; then
    mkdir -p "${NONO_ACL_REFRESH:h}"
    touch "${NONO_ACL_REFRESH}"
    REFRESH_NONO_KEYCHAIN_ACL=1
  fi
}

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
# "${account}". The reader differs per store, and so must the access grant:
#
#   - "nono" items are read by the nono binary itself when it sets up the sandbox,
#     non-interactively. This script signs that binary with a stable local
#     identity, and these items grant that identity access via -T. This survives
#     mise upgrades after the replacement binary is re-signed. We also list
#     `security` itself so this script can update values without re-triggering
#     authorization.
#   - "mise" items are read by the Apple-signed `security` CLI (via mise's
#     exec()), which is trusted by default; -A keeps them readable with no prompt.
#     Adding -T here would instead LOCK them to nono and make mise prompt.
#
# The first stable-signing migration recreates each cached nono item with the new
# ACL. Existing items then preserve their ACLs on normal syncs. Set
# REFRESH_NONO_KEYCHAIN_ACL=1 for a deliberate repair if the local signing
# identity or Keychain ACL was replaced.
function kc_add() {
  local service="$1" account="$2" value="$3"
  local -a trust
  local current_value
  if [[ "${service}" == "nono" && -n "${NONO_BIN}" ]]; then
    trust=(-T "${NONO_BIN}" -T "${SECURITY}")
  else
    [[ "${service}" == "nono" ]] \
      && log info "  nono not found; granting ${account} to any app (-A)"
    trust=(-A)
  fi
  if "${SECURITY}" find-generic-password -a "${account}" -s "${service}" >/dev/null 2>&1; then
    if [[ "${service}" == "nono" && -n "${NONO_BIN}" && "${REFRESH_NONO_KEYCHAIN_ACL}" == "1" ]]; then
      # Recreating an item lets this trusted setup process establish the new ACL
      # directly. Updating an existing ACL with -U -T makes macOS request the
      # login password separately for every item.
      "${SECURITY}" delete-generic-password -a "${account}" -s "${service}" >/dev/null
      "${SECURITY}" add-generic-password -a "${account}" -s "${service}" -w "${value}" "${trust[@]}"
    elif [[ "${service}" == "nono" ]]; then
      # Do not run add-generic-password -U for an unchanged Nono item: macOS can
      # replace its access metadata and discard the persistent signed-Nono grant.
      # Recreate only when 1Password contains a genuinely different value.
      current_value="$("${SECURITY}" find-generic-password \
        -a "${account}" -s "${service}" -w 2>/dev/null || true)"
      if [[ "${current_value}" != "${value}" ]]; then
        "${SECURITY}" delete-generic-password -a "${account}" -s "${service}" >/dev/null
        "${SECURITY}" add-generic-password -a "${account}" -s "${service}" -w "${value}" "${trust[@]}"
      fi
    else
      # mise items are intentionally available through the Apple-signed security
      # CLI, so their values can continue to be refreshed in place.
      "${SECURITY}" add-generic-password -a "${account}" -s "${service}" -w "${value}" -U
    fi
  else
    "${SECURITY}" add-generic-password -a "${account}" -s "${service}" -w "${value}" "${trust[@]}"
  fi
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
  mkdir -p "${DEV_WORKSPACE}/work" "${DEV_WORKSPACE}/personal"
  [[ -f "${SCRIPT_DIR}/work.mise.toml" ]] \
    && install -m 0644 "${SCRIPT_DIR}/work.mise.toml" "${DEV_WORKSPACE}/work/.mise.toml"
  [[ -f "${SCRIPT_DIR}/personal.mise.toml" ]] \
    && install -m 0644 "${SCRIPT_DIR}/personal.mise.toml" "${DEV_WORKSPACE}/personal/.mise.toml"

  log info "Done."
}

function main() {
  log info "Setting up env..."
  sign_nono
  require_op
  sync_secrets
  if [[ "${REFRESH_NONO_KEYCHAIN_ACL}" == "1" ]]; then
    mkdir -p "${NONO_ACL_CONFIGURED:h}"
    touch "${NONO_ACL_CONFIGURED}"
    rm -f "${NONO_ACL_REFRESH}"
  fi
  write_mise_files
  log info "Done."
}

main "$@"
