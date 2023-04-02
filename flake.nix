{
  description = "Otavio Salvador's NixOS/Home Manager config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv.url = "github:cachix/devenv";
    disko.url = "github:nix-community/disko";
    sops-nix.url = "github:Mic92/sops-nix";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    colmena.url = "github:zhaofengli/colmena";
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

      packages = builtins.foldl'
        (packages: hostname:
          let
            inherit (self.nixosConfigurations.${hostname}.config.nixpkgs) system;
            targetConfiguration = self.nixosConfigurations.${hostname};
          in
          packages // {
            ${system} = (packages.${system} or { }) // {
              "${hostname}-install-iso" = lib.mkInstallerForSystem { inherit hostname targetConfiguration system; };
            };
          })
        { }
        # FIXME: We shoudl convert to (builtins.attrNames self.nixosConfigurations) once all hosts
        # move to 'disko' as it is used for partitioning.
        [ "micro" ];

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
