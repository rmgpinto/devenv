#!/bin/zsh -eo pipefail

function sudo_touch_id() {
  if [[ -f "sudo-touch-id.sh" ]]; then
    ./sudo-touch-id.sh
  fi
}

function system_settings() {
  if [[ -f "system-settings.sh" ]]; then
    ./system-settings.sh
  fi
}

function dock() {
  if [[ -f "dock.sh" ]]; then
    ./dock.sh
  fi
}

function finder() {
  if [[ -f "finder.sh" ]]; then
    ./finder.sh
  fi
}

function safari() {
  if [[ -f "safari.sh" ]]; then
    ./safari.sh
  fi
}

function activity_monitor() {
  if [[ -f "activity-monitor.sh" ]]; then
    ./activity-monitor.sh
  fi
}

function raycast() {
  if [[ -f "raycast.sh" ]]; then
    ./raycast.sh
  fi
}

function hostname() {
  if [[ -f "hostname.sh" ]]; then
    ./hostname.sh
  fi
}

function remap_keys() {
  if [[ -f "remap-keys.sh" ]]; then
    ./remap-keys.sh
  fi
}

function outdated_packages() {
  if [[ -f "outdated-packages.sh" ]]; then
    ./outdated-packages.sh
  fi
}

function backup_git_ignored_work() {
  if [[ -f "backup-git-ignored-work.sh" ]]; then
    ./backup-git-ignored-work.sh
  fi
}

function main() {
  sudo_touch_id
  system_settings
  dock
  finder
  safari
  activity_monitor
  raycast
  hostname
  remap_keys
  outdated_packages
  backup_git_ignored_work
}

main

