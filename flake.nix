{
  description = "Otavio Salvador's NixOS/Home Manager config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";

      # used for tests only so we can ignore it.
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.stable.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, ... }@inputs:
    let
      overlays = with inputs; [
        (import ./overlays)

        emacs-overlay.overlay
        sops-nix.overlays.default
      ];

      lib = import ./lib { inherit inputs overlays; };
    in
    {
      nixosConfigurations = {
        micro = lib.mkSystem {
          hostname = "micro";
          system = "x86_64-linux";
          users = [ "otavio" ];
        };

        nano = lib.mkSystem {
          hostname = "nano";
          system = "x86_64-linux";
          users = [ "otavio" ];
        };

        # My wife device
        poirot = lib.mkSystem {
          hostname = "poirot";
          system = "x86_64-linux";
          users = [ "bruna" "otavio" ];
        };
      };

      homeConfigurations = {
        otavio = lib.mkHome {
          system = "x86_64-linux";
          username = "otavio";

          graphical = false;
        };
      };

      # Generate the custom installer with:
      # $: nix build .#mkInstallerIso
      mkInstallerIso = (lib.mkSystem {
        hostname = "installer";
        system = "x86_64-linux";
        users = [ "otavio" ];

        graphical = false;
      }).config.system.build.isoImage;

      colmena = lib.mkColmenaFromNixOSConfigurations self.nixosConfigurations;
    } // inputs.flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import inputs.nixpkgs { inherit system overlays; };
      in
      {
        devShells.default = inputs.devenv.lib.mkShell {
          inherit inputs pkgs;

          modules = [
            {
              packages = with pkgs; [
                colmena
                home-manager
                sops
              ];
            }
          ];
        };

        formatter = pkgs.writeShellApplication {
          name = "normalise_nix";
          runtimeInputs = with pkgs; [ nixpkgs-fmt statix ];
          text = ''
            set -o xtrace
            nixpkgs-fmt "$@"
            statix fix "$@"
          '';
        };

        checks = {
          lint = pkgs.runCommand "lint-code" { } ''
            ${pkgs.statix}/bin/statix check ${./.}

            # We need to produce it at end to avoid error.
            touch $out
          '';

          format = pkgs.runCommand "check-format" { } ''
            # Check Nix format.
            ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${./.}

            # We need to produce it at end to avoid error.
            touch $out
          '';
        };
      });

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://otavio-nix-config.cachix.org"
    ];

    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "otavio-nix-config.cachix.org-1:4HXl0KPGJ0+tkTUn/0tHRpz1wJst9MxovLjKbsPnqS4="
    ];
  };
}
