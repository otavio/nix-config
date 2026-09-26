{
  inputs,
  flake,
  hostName,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = {
      inherit flake hostName inputs;
      graphical = true;
    };
  };
}
