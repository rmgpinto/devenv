#!/bin/zsh -eo pipefail

function log() {
  local timestamp=$(date +"%H:%M:%S")
  local log_level=$1
  local message=$2
  local color_reset="\033[0m"
  local color_info="\033[32m"  # Green
  local color_debug="\033[34m" # Blue
  local color_error="\033[31m" # Red
  case $log_level in
    info)
      local color=$color_info
      ;;
    debug)
      local color=$color_debug
      ;;
    error)
      local color=$color_error
      ;;
    *)
      echo "Invalid log level. Use info, debug, or error."
      return 1
      ;;
  esac
  local log_level_upper=$(echo "$log_level" | tr '[:lower:]' '[:upper:]')
  echo -e "${timestamp} ${color}${log_level_upper}${color_reset} - ${message}"
}

