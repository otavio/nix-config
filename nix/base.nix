{ config, pkgs, ... }:
let
  local-scripts = pkgs.stdenv.mkDerivation {
    name = "local-scripts";
    src = ../nix/scripts;
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
    tmux
    tmuxp
    topgrade
    tree
    xclip

    aspell
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science
    aspellDicts.pt_BR

    nixfmt

    awscli2
  ];

  services.gpg-agent.enable = true;
  programs.msmtp.enable = true;

  home.sessionVariables = {
    TERMINAL = "alacritty";
    TERM = "xterm-256color";
  };

  home.file = {
    ".aspell.conf".source = ../nix/aspell/aspell.conf;
    ".emacs.d" = { source = ../nix/emacs.d; recursive = true; };
    ".gitconfig".source = ../nix/git/config;
    ".msmtprc".source = ../nix/msmtp/msmtprc;
    ".patman".source = ../nix/git/patman;
    ".tmux.conf".source = ../nix/tmux/tmux.conf;
    ".tmuxp" = { source = ../nix/tmux/tmuxp; recursive = true; };
    ".yocto/site.conf".source = ../nix/yocto/site.conf;
  };
}
