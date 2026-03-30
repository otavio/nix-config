{ inputs, flake, hostName, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs flake hostName;
      graphical = true;
    };
  };
}
