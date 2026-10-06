{ inputs, pkgs, ... }:
let
  emacsWithPackages = pkgs.emacsWithPackagesFromUsePackage {
    config = ./settings.org;

    # `use-package-always-ensure` to `t` in your config.
    alwaysEnsure = true;

    # For Org mode babel files, by default only code blocks with
    # `:tangle yes` are considered. Setting `alwaysTangle` to `true`
    # will include all code blocks missing the `:tangle` argument,
    # defaulting it to `yes`.
    alwaysTangle = true;

    extraEmacsPackages = epkgs: [
      (epkgs.trivialBuild {
        pname = "bitbake-modes";
        version = "0.8.0-unstable-2026-02-23";
        src = pkgs.fetchFromBitbucket {
          owner = "olanilsson";
          repo = "bitbake-modes";
          rev = "3515851f7100514f621dfcf8e20226f78cf6a24a";
          hash = "sha256-l61/n/4jz8256Jk9DPG/Alm2Lj/kIwcSiJ/i8xle5yA=";
        };

        packageRequires = [ epkgs.mmm-mode ];
      })
    ];
  };
in
{
  nixpkgs.overlays = [
    inputs.emacs-overlay.overlay
  ];
  home = {
    packages = with pkgs; [
      keychain
      emacs-all-the-icons-fonts

      emacsWithPackages

      # Markdown
      multimarkdown

      # Used in lsp-mode
      inputs.pedantix.packages.${pkgs.stdenv.hostPlatform.system}.pedantix-wrapped
      nil

      aspell
      aspellDicts.en
      aspellDicts.pt_BR
    ];
    sessionVariables.EDITOR = "emacs -nw";
    file = {
      ".emacs.d/init.el".text = ''
        ;;; init.el --- Entry point -*- lexical-binding: t; -*-
        (org-babel-load-file "~/.emacs.d/settings.org")
      '';

      ".emacs.d/settings.org" = {
        source = ./settings.org;

        onChange = ''
          # We need to ensure we regenerate the Emacs Lisp file for the changes be
          # applied in next start.
          rm -f ~/.emacs.d/settings.el

          # Remove the ELPA downloaded files so we don't leave old ones.
          rm -rf ~/.emacs.d/elpa
        '';
      };
    };
  };
  services.emacs.package = emacsWithPackages;
}
