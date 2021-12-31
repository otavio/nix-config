{ config, pkgs, ... }:
let
  emacs-overlay = import (pkgs.fetchFromGitHub {
    owner = "nix-community";
    repo = "emacs-overlay";
    rev = "17e7812904d8c081a27e77f71d31aee916cf0662";
    sha256 = "sha256-dGXlHwxGw2ight883p21ZWRtNqeIrJIH0gyzZ/8syjM=";
  });

  nixpkgs = import <nixpkgs> {
    overlays = [ emacs-overlay ];
  };

  emacsWithPackages = (nixpkgs.emacsWithPackagesFromUsePackage
    {
      config = ./emacs.d/settings.org;

      # `use-package-always-ensure` to `t` in your config.
      alwaysEnsure = true;

      # For Org mode babel files, by default only code blocks with
      # `:tangle yes` are considered. Setting `alwaysTangle` to `true`
      # will include all code blocks missing the `:tangle` argument,
      # defaulting it to `yes`.
      alwaysTangle = true;
    });
in
{
  home.packages = with nixpkgs; [
    emacs-all-the-icons-fonts

    emacsWithPackages
  ];

  home.sessionVariables.EDITOR = "emacs -nw";
  home.file.".emacs.d" = {
    source = ../nix/emacs.d;
    recursive = true;
  };

  services.emacs = {
    enable = true;
    package = emacsWithPackages;
  };
}
