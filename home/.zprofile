#
# ~/.zprofile — sourced by zsh for login shells only.
#
# Autostart Hyprland on the first console login (tty1) of jarvis.
# Runs only when there's no display yet, we're on virtual terminal 1,
# and this is jarvis — so terminal tabs, SSH sessions, and other machines
# are unaffected. `exec` replaces the login shell with the compositor, so
# quitting Hyprland logs you out instead of dropping to a bare prompt.
#
if [[ -z $WAYLAND_DISPLAY && -z $DISPLAY && $XDG_VTNR == 1 && $HOST == jarvis ]]; then
  exec start-hyprland
fi
