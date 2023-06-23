{
  description = "Otavio Salvador's NixOS/Home Manager config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lab-ossystems.url = "github:OSSystems/lab-builders-nix-config";

    nixos-hardware.url = "nixos-hardware";
    disko.url = "github:nix-community/disko";
    sops-nix.url = "github:Mic92/sops-nix";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    colmena.url = "github:zhaofengli/colmena";
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
      overlays = import ./overlays { inherit inputs outputs; };

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

        # My wife device
        poirot = mkSystem {
          hostname = "poirot";
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
            inherit (self.nixosConfigurations.${hostname}.config.nixpkgs) system;
            targetConfiguration = self.nixosConfigurations.${hostname};
          in
          packages // {
            ${system} = (packages.${system} or { }) // {
              "${hostname}-install-iso" = mkInstallerForSystem { inherit hostname targetConfiguration system; };
            };
          })
        (forEachSystem (pkgs: import ./pkgs { inherit pkgs; }))
        # FIXME: We shoudl convert to (builtins.attrNames self.nixosConfigurations) once all hosts
        # move to 'disko' as it is used for partitioning.
        [ "micro" ];

      colmena = mkColmenaFromNixOSConfigurations self.nixosConfigurations;
      devShells = forEachSystem (pkgs: {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            inputs.colmena.packages.${system}.colmena
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
