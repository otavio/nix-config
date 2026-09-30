{
  description = "Otavio Salvador's NixOS/Home Manager config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    red-tape = {
      url = "github:phaer/red-tape";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pedantix = {
      url = "github:Swarsel/pedantix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    nix-github-actions = {
      url = "github:nix-community/nix-github-actions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "nixos-hardware";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      # No nixpkgs follows: keep llm-agents' pin so it hits cache.numtide.com
      # instead of rebuilding every agent on each nixpkgs bump.
      url = "github:numtide/llm-agents.nix";
    };

    herdr-plugin-hunk = {
      url = "github:edmundmiller/herdr-plugin-hunk";
      flake = false;
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs";
      };
    };

    colmena = {
      # No nixpkgs follows: keep colmena's pin so it hits the cachix cache
      # instead of rebuilding from source on every nixpkgs bump.
      url = "github:zhaofengli/colmena";
    };

    whisrs = {
      url = "github:y0sif/whisrs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, ... }@inputs:
    inputs.red-tape.mkFlake {
      inherit inputs self;
      src = ./.;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      flake = {
        overlays = import ./overlays { inherit inputs; };

        colmenaHive =
          (import ./lib {
            inherit inputs;
            flake = self;
          }).mkColmenaFromNixOSConfigurations
            self.nixosConfigurations;

        homeConfigurations."otavio@generic-x86" = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = {
            inherit inputs;
            flake = self;
            graphical = false;
            hostName = "unknown";
          };
          modules = [ ./users/otavio/home/generic.nix ];
        };

        githubActions = inputs.nix-github-actions.lib.mkGithubMatrix {
          checks = { inherit (self.checks) x86_64-linux; };
        };
      };

      perSystem =
        { pkgs, ... }:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          inherit (inputs.nixpkgs) lib;
          hosts = lib.filterAttrs (
            _: cfg: cfg.config.nixpkgs.hostPlatform.system == system
          ) self.nixosConfigurations;
          installers = lib.mapAttrs (
            hostname: cfg:
            (import ./lib {
              inherit inputs;
              flake = self;
            }).mkInstaller
              {
                inherit hostname system;
                targetConfiguration = cfg;
              }
          ) hosts;
        in
        {
          # Building the images squashes each host's whole closure, so CI only
          # builds the installer systems (see garnix.yaml); the images stay
          # available on demand.
          packages = lib.mapAttrs' (
            hostname: installer:
            lib.nameValuePair "installer-iso-${hostname}" installer.config.system.build.isoImage
          ) installers;

          checks = lib.mapAttrs' (
            hostname: installer:
            lib.nameValuePair "installer-${hostname}" installer.config.system.build.toplevel
          ) installers;
        };
    };
}
