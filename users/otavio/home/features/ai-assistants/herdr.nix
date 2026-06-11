{ inputs, pkgs, ... }:

{
  home.packages = [
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    # notify-send, used by herdr's `[ui.toast] delivery = "system"` to route
    # agent-state popups to the desktop notification daemon (dunst).
    pkgs.libnotify
  ];
}
