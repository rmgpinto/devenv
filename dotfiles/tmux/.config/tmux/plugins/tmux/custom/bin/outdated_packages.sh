if [[ "$(cat ~/.config/tmux/custom/brew-outdated)" -eq "0" && "$(cat ~/.config/tmux/custom/mise-outdated)" -eq "0" ]]; then
  echo " "
else
  echo $(cat ~/.config/tmux/custom/brew-outdated) • $(cat ~/.config/tmux/custom/mise-outdated)
fi

