{ inputs, hostName, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
    inputs.colmena.nixosModules.deploymentOptions

    ./console.nix
    ./disable-global-dhcp.nix
    ./firmware.nix
    ./locale.nix
    ./home-manager.nix
    ./network.nix
    ./nix.nix
    ./nixpkgs.nix
    ./openssh.nix
    ./sops.nix
    ./sudo.nix
    ./upgrade-diff.nix
  ];

  networking.hostName = hostName;

  system.stateVersion = "26.05";
}
