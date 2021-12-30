{ config, pkgs, ... }:

{
  boot = {
    tmpOnTmpfs = true;
    kernelParams = [
      "quiet"
      "mitigations=off" # turn off mitigations so we gain some performance
      "fsck.repair=yes"
    ];
    #kernelPackages = pkgs.linuxPackages_latest;
  };

  # Collect nix store garbage and optimize daily.
  nix.gc.automatic = true;
  nix.optimise.automatic = true;

  # Users allowed to managed binary caches.
  nix.trustedUsers = [ "root" "otavio" ];

  # We need to allow use of those experimental features.
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  time.timeZone = "America/Sao_Paulo";

  programs.zsh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  home-manager.users.otavio =
    (import /home/otavio/.config/nixpkgs/home.nix { inherit pkgs config; });
  users.users.otavio = {
    isNormalUser = true;
    extraGroups = [ "dialout" "wheel" "networkmanager" ];
    uid = 1000;
    shell = pkgs.zsh;
  };

  # In case if it's enabled, I should have access to use it.
  users.extraGroups.docker.members = [ "otavio" ];
  users.extraGroups.vboxusers.members = [ "otavio" ];

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    cachix
    wget
    gitRepo
    python3
    git
    zile
    nettools # for ifconfig
    psmisc # for killall
    home-manager
  ];
}
