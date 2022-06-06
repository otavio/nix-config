{
  description = "Otavio Salvador's NixOS/Home Manager config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";

      # used for tests only so we can ignore it.
      inputs.nixpkgs-21_11.follows = "nixpkgs";
      inputs.nixpkgs-22_05.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };

    utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.stable.follows = "nixpkgs";
      inputs.utils.follows = "utils";
    };
  };

  outputs = { self, ... }@inputs:
    let
      overlays = with inputs; [
        (import ./overlays)

        emacs-overlay.overlay
        sops-nix.overlay
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
    } // inputs.utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import inputs.nixpkgs { inherit system overlays; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            colmena
            home-manager
            sops
          ];
        };

        checks = {
          format = pkgs.runCommand "check-format" { } ''
            # Check Nix format.
            ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${./.}

            # We need to produce it at end to avoid error.
            touch $out
          '';
        };
      });
}
