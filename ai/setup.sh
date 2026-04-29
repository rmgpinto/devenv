#!/bin/zsh -eo pipefail

source "../utils/log.sh"

# ai-sandbox: a restricted macOS user for AI agents.
#
# - Cannot access your home directory
# - Runs with standard user privileges (no sudo)
# - Cannot modify system files
# - Has no access to mounted drives
#
# - writable:  /Users/Shared/dev              -- shared workspace for host user & ai-sandbox
# - writable:  /Users/ai-sandbox              -- ai-sandbox's home directory
# - readable:  /usr, /bin, /etc, /opt         -- system directories
# - no access: /Users/*                       -- other user directories
# - writable:  /Volumes/Macintosh HD          -- accessible as per file permissions
# - no access: /Volumes/*                     -- cannot access mounted/remote/network drives

SANDBOX_USER="ai-sandbox"
SANDBOX_GROUP="ai-sandbox"
SANDBOX_HOME="/Users/${SANDBOX_USER}"
SHARED_WORKSPACE="/Users/Shared/dev"
SANDBOX_PROFILE_DIR="/var/ai-sandbox"
SANDBOX_PROFILE="${SANDBOX_PROFILE_DIR}/sandbox.sb"
SUDOERS_FILE="/etc/sudoers.d/50-ai-sandbox-${USER}"
SB_BIN="/usr/local/bin/sb"
DEVENV_AI_DIR="$(cd "$(dirname "$0")" && pwd)"

function setup_group() {
  log info "Creating ${SANDBOX_GROUP} group..."
  if ! dscl . -read "/Groups/${SANDBOX_GROUP}" &>/dev/null; then
    sudo dseditgroup -o create "${SANDBOX_GROUP}"
  fi
  log info "Done."
}

function setup_user() {
  log info "Creating ${SANDBOX_USER} user..."
  if ! dscl . -read "/Users/${SANDBOX_USER}" &>/dev/null; then
    sudo sysadminctl -addUser "${SANDBOX_USER}" \
      -fullName "${SANDBOX_USER}" \
      -home "${SANDBOX_HOME}" \
      -shell /bin/zsh \
      -password "Aa1!$(openssl rand -base64 32)"
    sudo dscl . -create "/Users/${SANDBOX_USER}" IsHidden 1
  fi

  # Remove from staff so the user can't read other users' staff-owned files.
  sudo dseditgroup -o edit -d "${SANDBOX_USER}" -t user staff 2>/dev/null || true

  # Both the sandbox user and the host user belong to the sandbox group.
  if ! dseditgroup -o checkmember -m "${SANDBOX_USER}" "${SANDBOX_GROUP}" &>/dev/null; then
    sudo dseditgroup -o edit -a "${SANDBOX_USER}" -t user "${SANDBOX_GROUP}"
  fi
  if ! dseditgroup -o checkmember -m "${USER}" "${SANDBOX_GROUP}" &>/dev/null; then
    sudo dseditgroup -o edit -a "${USER}" -t user "${SANDBOX_GROUP}"
  fi

  sudo mkdir -p "${SANDBOX_HOME}"
  sudo chown "${SANDBOX_USER}:${SANDBOX_GROUP}" "${SANDBOX_HOME}"
  sudo chmod 0700 "${SANDBOX_HOME}"
  log info "Done."
}

function setup_shared() {
  log info "Setting up ${SHARED_WORKSPACE}..."
  if [[ ! -d "${SHARED_WORKSPACE}" ]]; then
    sudo mkdir -p "${SHARED_WORKSPACE}"
    sudo chown "${SANDBOX_USER}:${SANDBOX_GROUP}" "${SHARED_WORKSPACE}"
    sudo chmod 0700 "${SHARED_WORKSPACE}"
  fi

  # Full RW for host and sandbox, applied recursively so pre-existing subdirs
  # (which don't inherit retroactively from a top-level ACL) also get access.
  # Additive only — macOS dedupes identical ACEs, so re-runs don't accumulate.
  # Filtered to dirs + regular files to skip broken symlinks, sockets, etc.
  local acl_host="user:${USER} allow read,write,execute,delete,add_file,add_subdirectory,list,search,file_inherit,directory_inherit"
  local acl_sbox="user:${SANDBOX_USER} allow read,write,execute,delete,add_file,add_subdirectory,list,search,file_inherit,directory_inherit"

  # Fast path: if the workspace root already carries both ACEs, prior runs
  # have walked the tree, and inherit flags propagate the ACEs to anything
  # newly created since. Skip the (slow) recursive pass.
  local root_acls
  root_acls=$(/bin/ls -lde "${SHARED_WORKSPACE}" 2>/dev/null)
  if [[ "${root_acls}" == *"user:${USER} allow"* \
     && "${root_acls}" == *"user:${SANDBOX_USER} allow"* ]]; then
    log info "ACLs already present at root; skipping recursive pass."
    log info "Done."
    return
  fi

  sudo find "${SHARED_WORKSPACE}" \( -type d -o -type f \) -exec chmod +a "${acl_host}" {} +
  sudo find "${SHARED_WORKSPACE}" \( -type d -o -type f \) -exec chmod +a "${acl_sbox}" {} +
  log info "Done."
}

function setup_sandbox_profile() {
  log info "Installing sandbox profile..."
  sudo mkdir -p "${SANDBOX_PROFILE_DIR}"
  sudo chmod 0755 "${SANDBOX_PROFILE_DIR}"
  sed \
    -e "s|{{SHARED_WORKSPACE}}|${SHARED_WORKSPACE}|g" \
    -e "s|{{SANDBOX_USER}}|${SANDBOX_USER}|g" \
    templates/sandbox.sb \
    | sudo tee "${SANDBOX_PROFILE}" > /dev/null
  sudo chmod 0444 "${SANDBOX_PROFILE}"
  log info "Done."
}

function setup_sudoers() {
  log info "Installing sudoers entry..."
  local tmp
  tmp=$(sudo mktemp "$(dirname "${SUDOERS_FILE}")/.sudoers.XXXXXX")
  echo "${USER} ALL=(${SANDBOX_USER}) NOPASSWD: ALL" | sudo tee "${tmp}" > /dev/null
  sudo chmod 0440 "${tmp}"
  if sudo visudo -c -f "${tmp}" >/dev/null; then
    sudo mv -f "${tmp}" "${SUDOERS_FILE}"
  else
    sudo rm -f "${tmp}"
    log error "sudoers file failed validation"
    exit 1
  fi
  log info "Done."
}

function setup_sb_cli() {
  log info "Installing sb wrapper to ${SB_BIN}..."
  sudo install -m 0755 bin/sb "${SB_BIN}"
  log info "Done."
}

function setup_workspace() {
  log info "Stowing workspace files..."
  sudo rm -f "${SHARED_WORKSPACE}/.mise.toml" "${SHARED_WORKSPACE}/CLAUDE.md"
  /opt/homebrew/bin/stow --no-folding -d "${DEVENV_AI_DIR}" sb -t "${SHARED_WORKSPACE}"
  ln -s personal/devenv/CLAUDE.md "${SHARED_WORKSPACE}/CLAUDE.md"
  sudo -u "${SANDBOX_USER}" mkdir -p "${SANDBOX_HOME}/.config/mise"
  local tmp
  tmp=$(mktemp)
  sed 's/^REMOVE_//' "../.mise.local.toml" > "${tmp}"
  sudo install -o "${SANDBOX_USER}" -g "${SANDBOX_GROUP}" -m 0600 "${tmp}" "${SANDBOX_HOME}/.config/mise/config.toml"
  rm -f "${tmp}"
  log info "Done."
}

function setup_claude() {
  log info "Stowing Claude Code settings..."
  sudo mkdir -p "${SANDBOX_HOME}/.claude"
  sudo chown "${SANDBOX_USER}:${SANDBOX_GROUP}" "${SANDBOX_HOME}/.claude"
  sudo rm -f "${SANDBOX_HOME}/.claude/settings.json"
  sudo -u "${SANDBOX_USER}" /opt/homebrew/bin/stow --no-folding \
    -d "${DEVENV_AI_DIR}/dotfiles" claude -t "${SANDBOX_HOME}"
  log info "Done."
}

function setup_git() {
  # Workspace files are owned by the host user, so git refuses to operate on
  # them as ai-sandbox without an explicit safe.directory allowlist.
  log info "Stowing git config..."
  sudo -u "${SANDBOX_USER}" mkdir -p "${SANDBOX_HOME}/.config/git"
  sudo -u "${SANDBOX_USER}" /opt/homebrew/bin/stow --no-folding \
    -d "${DEVENV_AI_DIR}/dotfiles" git -t "${SANDBOX_HOME}"
  if ! sudo -u "${SANDBOX_USER}" test -L "${SANDBOX_HOME}/.gitconfig"; then
    sudo -u "${SANDBOX_USER}" rm -f "${SANDBOX_HOME}/.gitconfig"
    sudo -u "${SANDBOX_USER}" ln -s "${SANDBOX_HOME}/.config/git/config" "${SANDBOX_HOME}/.gitconfig"
  fi
  log info "Done."
}

function setup_keychain() {
  log info "Ensuring login keychain exists for ${SANDBOX_USER}..."
  local kc="${SANDBOX_HOME}/Library/Keychains/login.keychain-db"
  if sudo -u "${SANDBOX_USER}" test -f "${kc}"; then
    log info "Already present, skipping."
    return
  fi
  # Empty password: the sandbox account never logs in via GUI. The keychain
  # only exists so apps using Security framework don't trigger a "reset login
  # keychain?" dialog (Claude Code's credential layer is a known offender).
  sudo -H -u "${SANDBOX_USER}" security create-keychain    -p "" "${kc}"
  sudo -H -u "${SANDBOX_USER}" security set-keychain-settings    "${kc}"
  sudo -H -u "${SANDBOX_USER}" security unlock-keychain    -p "" "${kc}"
  sudo -H -u "${SANDBOX_USER}" security default-keychain   -s    "${kc}"
  log info "Done."
}

function setup_mise() {
  log info "Installing mise tools in sandbox..."
  "${SB_BIN}" "${SHARED_WORKSPACE}" -- /opt/homebrew/bin/mise settings set experimental true
  "${SB_BIN}" "${SHARED_WORKSPACE}" -- /opt/homebrew/bin/mise settings set trusted_config_paths '["/Users/Shared/dev"]'
  "${SB_BIN}" "${SHARED_WORKSPACE}" -- /opt/homebrew/bin/mise plugins update
  "${SB_BIN}" "${SHARED_WORKSPACE}" -- /opt/homebrew/bin/mise install
  "${SB_BIN}" "${SHARED_WORKSPACE}" -- /opt/homebrew/bin/mise upgrade
  "${SB_BIN}" "${SHARED_WORKSPACE}" -- /opt/homebrew/bin/mise prune -y
  log info "Done."
}

function main() {
  setup_group
  setup_user
  setup_shared
  setup_sandbox_profile
  setup_sudoers
  setup_sb_cli
  setup_workspace
  setup_claude
  setup_git
  setup_keychain
  setup_mise
}

main
