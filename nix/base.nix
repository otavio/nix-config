{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    stow # for old dotconfig files copy

    bat
    emacs
    exa
    fzf
    gitAndTools.delta
    nnn
    tmux
    tmuxp
    tree
    keychain
    rustup
    topgrade
    htop

    aspell
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science
    aspellDicts.pt_BR
  ];

  programs.msmtp.enable = true;

  home.sessionVariables = {
    EDITOR = "emacs -nw";
    TERM = "xterm-256color";
  };

  home.file = {
    ".aspell.conf".source = ../nix/aspell/aspell.conf;
    ".emacs.d" = {
      source = ../nix/emacs;
      recursive = true;
    };
    ".gitconfig".source = ../nix/git/config;
    ".msmtprc".source = ../nix/msmtp/msmtprc;
    ".patman".source = ../nix/git/patman;
    ".tmux.conf".source = ../nix/tmux/tmux.conf;
    ".tmuxp" = {
      source = ../nix/tmux/tmuxp;
      recursive = true;
    };
    ".yocto/site.conf".source = ../nix/yocto/site.conf;
  };
}
