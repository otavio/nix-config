{ pkgs, ... }:

{
  home.packages = [
    pkgs.herdr
    # notify-send, used by herdr's `[ui.toast] delivery = "system"` to route
    # agent-state popups to the desktop notification daemon (dunst).
    pkgs.libnotify
  ];
}
