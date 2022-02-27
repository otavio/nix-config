{ config, pkgs, ... }:
let
  emacs-overlay = import (pkgs.fetchFromGitHub {
    owner = "nix-community";
    repo = "emacs-overlay";
    rev = "beffadfb0345078ab3d630e9ca6e0aaf061d3aa5";
    sha256 = "sha256-UxMJVmI5juZVxUnbLSB/O1tvL8JJz9IaVJYqQB3Dszs=";
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
  home.file = {
    ".emacs.d/init.el".text = "(org-babel-load-file \"~/.emacs.d/settings.org\")";

    ".emacs.d/settings.org" = {
      source = ../nix/emacs.d/settings.org;

      onChange = ''
        # We need to ensure we regenerate the Emacs Lisp file for the changes be
        # applied in next start.
        rm -f ~/.emacs.d/settings.el

        # Remove the ELPA downloaded files so we don't leave old ones.
        rm -rf ~/.emacs.d/elpa
      '';
    };
  };

  services.emacs = {
    enable = true;
    package = emacsWithPackages;
  };
}
