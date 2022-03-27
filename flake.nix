{
  description = "Otavio Salvador's NixOS/Home Manager config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { ... }@inputs:
    let
      overlays = with inputs; [
        (import ./overlays)

        emacs-overlay.overlay
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
    } // inputs.utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import inputs.nixpkgs { inherit system overlays; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ sops home-manager ];
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
