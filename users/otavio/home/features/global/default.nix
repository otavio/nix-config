{
  imports = [
    ../git
    ../home-manager
    ../nix
    ../ssh
    ../tmux
  ];

  systemd.user.startServices = "sd-switch";
}
