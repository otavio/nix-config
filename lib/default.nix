{ inputs, outputs }:

{
  mkColmenaFromNixOSConfigurations = conf:
    inputs.colmena.lib.makeHive ({
      meta = {
        description = "my personal machines";
        # This can be overriden by node nixpkgs
        nixpkgs = import inputs.nixpkgs { hostSystem = "x86_64-linux"; };
        nodeNixpkgs = builtins.mapAttrs (_: value: value.pkgs) conf;
        nodeSpecialArgs = builtins.mapAttrs (_: value: value._module.specialArgs) conf;
      };
    } // builtins.mapAttrs (_: value: { imports = value._module.args.modules; }) conf);

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
              builtins.listToAttrs
                (builtins.map
                  (u: { name = u; value = import ../users/${u}/home/${hostname}.nix; })
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

  mkHome = module: system:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs { inherit system; };

      extraSpecialArgs = {
        inherit inputs outputs;

        graphical = false;
        hostname = "unknown";
      };

      modules = [ module ];
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
