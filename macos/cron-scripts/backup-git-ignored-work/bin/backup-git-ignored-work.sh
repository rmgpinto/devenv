#!/bin/zsh -eo pipefail

source "${HOME}/dev/personal/devenv/utils/log.sh"

function create_log_file() {
  if [ -f /tmp/backupgitingoredwork.log ]; then
    echo "" > /tmp/backupgitingoredwork.log
  fi
}

function add_to_backup_json() {
    local index=$1
    local backup_dir=$2
    local filename=$3
    local content=$(cat "$filename")
    local backup_file="${backup_dir}/backup.jsonl"
    log info "Backing up $filename"
    echo $content > "${backup_dir}/${index}.work"
    echo "{\"${filename}\": \"${index}.work\"}" >> ${backup_file}
}

function main() {
  create_log_file
  local backup_dir="${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Work/code/git-ignored-backups"
  mkdir -p ${backup_dir}
  if [[ -f ${backup_dir}/backup.jsonl ]]; then
    rm ${backup_dir}/backup.jsonl
  fi
  local git_ignored_files=($(find "${HOME}/dev/work" -type f -name "*.work"))
  local index=1
  for git_ignored_file in ${git_ignored_files[@]}; do
    add_to_backup_json ${index} ${backup_dir} ${git_ignored_file}
    index=$((index + 1))
  done
}

main

