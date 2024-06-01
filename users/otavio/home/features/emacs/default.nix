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
        version = "0.5.3-unstable-2023-08-24";
        src = pkgs.fetchFromBitbucket {
          owner = "olanilsson";
          repo = "bitbake-modes";
          rev = "7bcfaaca9ec4646700361b293128ffeb00ba48e4";
          hash = "sha256-tGvJ2EtYsSAfyunrm+ccgBulYgTcHoVYvBhm6hKFyHw=";
        };

        packageRequires = [ epkgs.mmm-mode ];
      })
    ];

    override = epkgs: epkgs // {
      inherit (epkgs.nongnuPackages) nix-mode;
    };

    package = pkgs.emacs29-gtk3;
  };
in
{
  nixpkgs.overlays = [
    inputs.emacs-overlay.overlay
  ];

  home.packages = with pkgs; [
    keychain
    emacs-all-the-icons-fonts

    emacsWithPackages

    # Markdown
    multimarkdown

    # Used in lsp-mode
    nixpkgs-fmt
    nil

    aspell
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science
    aspellDicts.pt_BR
  ];

  home.sessionVariables.EDITOR = "emacs -nw";
  home.file = {
    ".emacs.d/init.el".text = "(org-babel-load-file \"~/.emacs.d/settings.org\")";

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

  services.emacs.package = emacsWithPackages;
}
