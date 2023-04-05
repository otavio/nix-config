{ inputs, outputs }:
let
  inherit (builtins) attrValues listToAttrs map mapAttrs;
  overlays = attrValues outputs.overlays ++ [
    inputs.emacs-overlay.overlay
  ];
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
        inherit inputs system hostname;
      };

      extraModules = [ inputs.colmena.nixosModules.deploymentOptions ];

      modules = [
        inputs.disko.nixosModules.disko

        ../hosts/${hostname}
        {
          networking.hostName = hostname;

          # Apply overlay and allow unfree packages
          nixpkgs = {
            inherit overlays;

            config.allowUnfree = true;
          };
        }

        inputs.home-manager.nixosModule
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
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
    let
      pkgs = import inputs.nixpkgs { inherit overlays system; };
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      extraSpecialArgs = {
        inherit inputs system graphical;
      };

      modules = [
        # Base configuration
        {
          home = {
            inherit username;
            homeDirectory = "/home/${username}";
          };

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
        inherit inputs system targetConfiguration;
      };

      extraModules = [ inputs.colmena.nixosModules.deploymentOptions ];

      modules = [
        inputs.disko.nixosModules.disko

        ../hosts/installer

        {
          networking.hostName = hostname;

          # Apply overlay and allow unfree packages
          nixpkgs = {
            inherit overlays;

            config.allowUnfree = true;
          };
        }
      ];
    }).config.system.build.isoImage;
}
