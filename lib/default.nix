{ inputs, flake }:

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

  mkInstallerForSystem =
    { hostname
    , targetConfiguration
    , system
    }:
    (inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs targetConfiguration flake;
        hostName = hostname;
      };

      extraModules = [ inputs.colmena.nixosModules.deploymentOptions ];

      modules = [
        { nixpkgs.hostPlatform = system; }

        inputs.disko.nixosModules.disko

        ./installer
      ];
    }).config.system.build.isoImage;
}
