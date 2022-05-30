{ inputs, overlays }:
let
  inherit (builtins) listToAttrs map mapAttrs;
in
{
  mkColmenaFromNixOSConfigurations = nixosConfigurations:
    {
      meta = {
        nixpkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          inherit overlays;
        };

        specialArgs = {
          inherit inputs;
        };
      };
    } // mapAttrs
      (name: value:
        {
          nixpkgs.system = value.config.nixpkgs.system;
          imports = value._module.args.modules;
        })
      (nixosConfigurations);

  mkSystem =
    { hostname
    , system
    , graphical ? true
    , users ? [ ]
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs system hostname;
      };

      extraModules = [ inputs.colmena.nixosModules.deploymentOptions ];

      modules = [
        inputs.sops-nix.nixosModules.sops

        ../hosts/${hostname}
        {
          networking.hostName = hostname;

          # Apply overlay and allow unfree packages
          nixpkgs = {
            inherit overlays;

            config.allowUnfree = true;
          };

          # Add each input as a registry
          nix.registry = inputs.nixpkgs.lib.mapAttrs'
            (n: v:
              inputs.nixpkgs.lib.nameValuePair (n) ({ flake = v; }))
            inputs;
        }

        inputs.home-manager.nixosModule
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users =
              listToAttrs
                (map
                  (u: { name = u; value = (import ../users/${ u}/home); })
                  users);

            extraSpecialArgs = {
              inherit inputs system graphical hostname;
            };
          };
        }

        # System wide config for each user
      ] ++ inputs.nixpkgs.lib.forEach users
        (u: ../users/${u}/system);
    };

  mkHome =
    { username
    , system
    , graphical ? false
    , hostname ? "unknown"
    }:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit username system;

      extraSpecialArgs = {
        inherit inputs system graphical;
      };

      homeDirectory = "/home/${username}";

      configuration = ../users/${username}/home;

      extraModules = [
        # Base configuration
        {
          nixpkgs = {
            inherit overlays;
            config.allowUnfree = true;
          };

          programs = {
            home-manager.enable = true;
            git.enable = true;
          };

          systemd.user.startServices = "sd-switch";
        }
      ];

      stateVersion = "22.05";
    };
}