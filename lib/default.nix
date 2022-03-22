{ inputs, overlays }:
let
  inherit (builtins) listToAttrs map;
in
{
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

      modules = [
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
              inherit inputs system graphical;
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
