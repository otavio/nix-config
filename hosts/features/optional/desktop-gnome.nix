{ config, lib, pkgs, ... }:

let
  cinnamon = config.services.xserver.desktopManager.cinnamon;

  cinnamonGSettingsOverrides = pkgs.cinnamon-gsettings-overrides.override {
    inherit (cinnamon) extraGSettingsOverridePackages extraGSettingsOverrides;
  };
in
{
  imports = [ ./desktop.nix ];

  services.xserver.enable = true;

  services.desktopManager.gnome.enable = true;

  # GNOME 49 ships a Wayland session only, and the LightDM greeter silently
  # falls back to the host default rather than starting it, so a user set to
  # GNOME lands in the default session instead. GDM starts Wayland sessions and
  # honours the per-user choice; it turns LightDM off by itself.
  services.displayManager.gdm.enable = true;

  # GNOME and Cinnamon each define this system-wide, so co-installing them is a
  # conflict. Keep Cinnamon's to leave the pre-existing sessions untouched;
  # GNOME users get their defaults from per-user dconf instead.
  environment.sessionVariables.NIX_GSETTINGS_OVERRIDES_DIR =
    lib.mkIf cinnamon.enable (lib.mkForce
      "${cinnamonGSettingsOverrides}/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas");
}
