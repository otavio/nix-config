{
  description = "Otavio Salvador's NixOS/Home Manager config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    red-tape = {
      url = "github:phaer/red-tape";
      inputs.nixpkgs.follows = "nixpkgs";
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

    claude-code-overlay = {
      url = "github:ryoppippi/claude-code-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-nix = {
      url = "github:secbear/codex-nix";
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

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    whisrs = {
      url = "github:y0sif/whisrs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, ... }@inputs:
    inputs.red-tape.mkFlake {
      inherit inputs self;
      src = ./.;
      systems = [ "x86_64-linux" "aarch64-linux" ];

      flake = {
        overlays = import ./overlays { };

        colmenaHive =
          (import ./lib { inherit inputs; flake = self; }).mkColmenaFromNixOSConfigurations self.nixosConfigurations;

        homeConfigurations."otavio@generic-x86" =
          inputs.home-manager.lib.homeManagerConfiguration {
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
        in
        {
          packages = builtins.foldl'
            (acc: hostname:
              let
                cfg = self.nixosConfigurations.${hostname};
                hostSystem = cfg.config.nixpkgs.hostPlatform.system;
              in
              if hostSystem == system then
                acc // {
                  "installer-iso-${hostname}" =
                    (import ./lib { inherit inputs; flake = self; }).mkInstallerForSystem {
                      inherit hostname system;
                      targetConfiguration = cfg;
                    };
                }
              else
                acc)
            { }
            (builtins.attrNames self.nixosConfigurations);
        };
    };
}
