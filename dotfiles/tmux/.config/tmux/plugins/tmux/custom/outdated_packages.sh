show_outdated_packages() {
  local index icon color text module

  index=$1
  icon="$(get_tmux_option "@catppuccin_outdated_packages_icon" "")"
  color="$(get_tmux_option "@catppuccin_outdated_packages_color" "$thm_magenta")"
  text="$(get_tmux_option "@catppuccin_outdated_packages_text" "#(cat ~/.config/tmux/custom/brew-outdated) • #(cat ~/.config/tmux/custom/mise-outdated)")"

  module=$(build_status_module "$index" "$icon" "$color" "$text")
  echo "$module"
}
