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

  # GNOME and Cinnamon each define this system-wide, so co-installing them is a
  # conflict. Keep Cinnamon's to leave the pre-existing sessions untouched;
  # GNOME users get their defaults from per-user dconf instead.
  environment.sessionVariables.NIX_GSETTINGS_OVERRIDES_DIR =
    lib.mkIf cinnamon.enable (lib.mkForce
      "${cinnamonGSettingsOverrides}/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas");
}
