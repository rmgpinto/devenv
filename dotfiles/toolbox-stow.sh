#!/bin/zsh -eo pipefail

TOOLBOX_DIR="${1:-${DEV_WORKSPACE:-${HOME}/dev}/work/Toolbox}"

if [[ ! -d "${TOOLBOX_DIR}/scripts" || ! -f "${TOOLBOX_DIR}/.toolbox/sammy.json" ]]; then
  print -u2 "Toolbox scripts or sammy.json not found in ${TOOLBOX_DIR}"
  exit 1
fi

mkdir -p "${TOOLBOX_DIR}/stow/bin" "${TOOLBOX_DIR}/stow/toolbox"
for SCRIPT in "${TOOLBOX_DIR}/scripts/"*.sh; do
  cp "${SCRIPT}" "${TOOLBOX_DIR}/stow/bin/${SCRIPT:t:r}"
  chmod +x "${TOOLBOX_DIR}/stow/bin/${SCRIPT:t:r}"
done
cp "${TOOLBOX_DIR}/.toolbox/sammy.json" "${TOOLBOX_DIR}/stow/toolbox/sammy.json"

sudo mkdir -p /usr/local/bin
if [[ -L "${HOME}/.config/toolbox" && ! -e "${HOME}/.config/toolbox" ]]; then
  unlink "${HOME}/.config/toolbox"
fi
mkdir -p "${HOME}/.config/toolbox"
sudo /opt/homebrew/bin/stow --dir="${TOOLBOX_DIR}/stow" \
  --target=/usr/local/bin bin
/opt/homebrew/bin/stow --dir="${TOOLBOX_DIR}/stow" \
  --target="${HOME}/.config/toolbox" toolbox
