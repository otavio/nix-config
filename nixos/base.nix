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

  time.timeZone = "America/Sao_Paulo";

  programs.zsh.enable = true;
  programs.zsh.interactiveShellInit = ''
    source ${pkgs.grml-zsh-config}/etc/zsh/zshrc
  '';
  programs.zsh.promptInit = ""; # or it replacez grml prompt.

  security.sudo.wheelNeedsPassword = false;

  home-manager.users.otavio = (import /home/otavio/.config/nixpkgs/home.nix { inherit pkgs config; });
  users.users.otavio = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    uid = 1000;
    shell = pkgs.zsh;
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    wget
    gitRepo python3
    git
    zile
    nettools        # for ifconfig
    psmisc          # for killall
    grml-zsh-config
    home-manager
  ];
}
