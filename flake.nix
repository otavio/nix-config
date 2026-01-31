{
  description = "Otavio Salvador's NixOS/Home Manager config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

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

    claude-code-overlay = {
      url = "github:ryoppippi/claude-code-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

    talon-nix = {
      url = "github:fidgetingbits/talon-nix?ref=overrides";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-github-actions.follows = "nix-github-actions";
    };

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nix-github-actions.follows = "nix-github-actions";
    };

    nix-secrets = {
      url = "git+ssh://git@github.com/otavio/nix-secrets?shallow=1";
    };
  };

  outputs = { self, ... }@inputs:
    let
      inherit (self) outputs;
      inherit (import ./lib { inherit inputs outputs; })
        mkSystem
        mkHome
        mkColmenaFromNixOSConfigurations
        mkInstallerForSystem
        ;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = f: inputs.nixpkgs.lib.genAttrs systems (sys: f pkgsFor.${sys});
      pkgsFor = inputs.nixpkgs.legacyPackages;
    in
    {
      overlays = import ./overlays { inherit inputs; };

      nixosConfigurations = {
        micro = mkSystem {
          hostname = "micro";
          system = "x86_64-linux";
          users = [ "otavio" ];
        };

        nano = mkSystem {
          hostname = "nano";
          system = "x86_64-linux";
          users = [ "otavio" ];
        };

        # My wife devices
        poirot = mkSystem {
          hostname = "poirot";
          system = "x86_64-linux";
          users = [ "bruna" "otavio" ];
        };

        miss-marple = mkSystem {
          hostname = "miss-marple";
          system = "x86_64-linux";
          users = [ "bruna" "otavio" ];
        };
      };

      homeConfigurations = {
        "otavio@generic-x86" = mkHome ./users/otavio/home/generic.nix "x86_64-linux";
      };

      packages = builtins.foldl'
        (packages: hostname:
          let
            inherit (self.nixosConfigurations.${hostname}.config.nixpkgs.hostPlatform) system;
            targetConfiguration = self.nixosConfigurations.${hostname};
          in
          packages // {
            ${system} = (packages.${system} or { }) // {
              "installer-iso-${hostname}" = mkInstallerForSystem { inherit hostname targetConfiguration system; };
            };
          })
        (forEachSystem (pkgs: import ./pkgs { inherit pkgs; }))
        (builtins.attrNames self.nixosConfigurations);

      colmenaHive = mkColmenaFromNixOSConfigurations self.nixosConfigurations;
      devShells = forEachSystem (pkgs: {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena
            home-manager
            sops
          ];
        };
      });

      formatter = forEachSystem (pkgs: pkgs.writeShellApplication {
        name = "normalise_nix";
        runtimeInputs = with pkgs; [ nixpkgs-fmt statix ];
        text = ''
          set -o xtrace
          nixpkgs-fmt "$@"
          statix fix "$@"
        '';
      });

      checks = forEachSystem (pkgs: {
        lint = pkgs.runCommand "lint-code" { nativeBuildInputs = with pkgs; [ nixpkgs-fmt deadnix statix ]; } ''
          deadnix --fail ${./.}
          #statix check ${./.} # https://github.com/nerdypepper/statix/issues/75
          nixpkgs-fmt --check ${./.}
          touch $out
        '';
      });
    };
}
