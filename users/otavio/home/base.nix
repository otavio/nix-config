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
  home.packages = with pkgs; [
    local-scripts

    cryptsetup
    gh
    git-review
    git-secret
    gitAndTools.delta
    gitRepo
    gping
    htop
    keychain
    mtr
    nnn
    patman
    tmux
    tmuxp
    topgrade
    tree
    xclip

    axel
    wget
    git
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
    ".gitconfig".source = ./git/config;
    ".msmtprc".source = ./msmtp/msmtprc;
    ".patman".source = ./git/patman;
    ".tmux.conf".source = ./tmux/tmux.conf;
    ".tmuxp" = { source = ./tmux/tmuxp; recursive = true; };
    ".yocto/site.conf".source = ./yocto/site.conf;
  };

  xdg.configFile."topgrade.toml".source = ./topgrade/topgrade.toml;
}
