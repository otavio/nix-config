{ config, pkgs, ... }:
let
  local-scripts = pkgs.stdenv.mkDerivation {
    name = "local-scripts";
    src = ./scripts;
    installPhase = ''
      mkdir -p $out/bin
      cp -r * $out/bin
    '';
  };
in
{
  programs.home-manager.enable = true;

  home.stateVersion = "22.11";

  home.packages = with pkgs; [
    local-scripts

    cryptsetup
    gping
    htop
    keychain
    mtr
    nnn
    tmux
    tmuxp
    tree
    xclip

    axel
    wget
    nettools # for ifconfig
    psmisc # for killall

    aspell
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science
    aspellDicts.pt_BR

    manix
    nixfmt

    awscli2
  ];

  services.gpg-agent.enable = true;
  programs.gpg.enable = true;
  programs.msmtp.enable = true;

  home.sessionVariables = {
    TERMINAL = "alacritty";
    TERM = "xterm-256color";
  };

  home.file = {
    ".emacs.d" = { source = ./emacs.d; recursive = true; };
    ".tmux.conf".source = ./tmux/tmux.conf;
    ".tmuxp" = { source = ./tmux/tmuxp; recursive = true; };
    ".yocto/site.conf".source = ./yocto/site.conf;
  };

  programs.topgrade = {
    enable = true;
    settings = {
      assume_yes = true;
      disable = [
        "emacs"
        "flutter"
        "home_manager"
        "nix"
        "node"
        "pip3"
      ];
      set_title = false;
      skip_notify = true;
      cleanup = true;
      pre_commands = {
        "nix-config" = "cd ~/src/nix-config && git pull --rebase --autostash";
      };
    };
  };
}
