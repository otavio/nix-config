{
  imports = [
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

  system.stateVersion = "23.11";
}
