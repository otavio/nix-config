{ config, pkgs, ... }:

{
  virtualisation.docker.enable = true;

  # FIXME: uncomented once Fabio include his config
  # home-manager.users.berton = (import /home/berton/.config/nixpkgs/home.nix { inherit pkgs config; });
  users.users.berton = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    uid = 1001;
  };

  users.users.otavio.extraGroups = [ "docker" ];
}
