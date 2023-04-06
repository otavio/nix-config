{ inputs, outputs }:
let
  inherit (builtins) attrValues listToAttrs map mapAttrs;
in
{
  mkColmenaFromNixOSConfigurations = nixosConfigurations:
    {
      meta = {
        nixpkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          overlays = builtins.attrValues outputs.overlays;
        };

        specialArgs = {
          inherit inputs outputs;
        };
      };
    } // mapAttrs
      (name: value:
        {
          nixpkgs.system = value.config.nixpkgs.system;
          imports = value._module.args.modules;
        })
      nixosConfigurations;

  mkSystem =
    { hostname
    , system
    , graphical ? true
    , users ? [ ]
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs outputs system hostname;
      };

      extraModules = [ inputs.colmena.nixosModules.deploymentOptions ];

      modules = [
        inputs.disko.nixosModules.disko

        ../hosts/${hostname}
        {
          networking.hostName = hostname;
        }

        {
          home-manager = {
            users =
              listToAttrs
                (map
                  (u: { name = u; value = import ../users/${ u}/home; })
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
      extraSpecialArgs = {
        inherit inputs outputs system graphical;
      };

      pkgs = inputs.nixpkgs.legacyPackages.${system};

      modules = [
        # Base configuration
        {
          home = {
            inherit username;

            homeDirectory = "/home/${username}";
          };

          programs = {
            home-manager.enable = true;
            git.enable = true;
          };

          systemd.user.startServices = "sd-switch";
        }

        ../users/${username}/home
      ];
    };

  mkInstallerForSystem =
    { hostname
    , targetConfiguration
    , system
    }:
    (inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs outputs system targetConfiguration;
      };

      extraModules = [ inputs.colmena.nixosModules.deploymentOptions ];

      modules = [
        inputs.disko.nixosModules.disko

        ../hosts/installer

        {
          networking.hostName = hostname;
        }
      ];
    }).config.system.build.isoImage;
}
