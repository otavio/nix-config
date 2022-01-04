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

  patman = pkgs.python3.pkgs.buildPythonApplication rec {
    pname = "patman";
    version = "2021.10";

    src = pkgs.fetchFromGitHub {
      repo = "u-boot";
      owner = "u-boot";
      rev = "v${version}";
      sha256 = "sha256-2CcIHGbm0HPmY63Xsjaf/Yy78JbRPNhmvZmRJAyla2U=";
    };

    patches = ./../patches/patman-expand-user-home-when-looking-for-the-alias-f.patch;

    sourceRoot = "source/tools/patman";

    makeWrapperArgs = [ "--prefix PATH : ${pkgs.gitFull}/bin" ];

    buildInputs = [ pkgs.git ];

    postInstall = ''
      cp README $out/bin
    '';

    doCheck = false;
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
    gitFull
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

    aspell
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science
    aspellDicts.pt_BR

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
