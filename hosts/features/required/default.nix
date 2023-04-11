{
  imports = [
    ./console.nix
    ./disable-global-dhcp.nix
    ./locale.nix
    ./home-manager.nix
    ./nix.nix
    ./nixpkgs.nix
    ./openssh.nix
    ./sops.nix
    ./sudo.nix
    ./upgrade-diff.nix
  ];

  system.stateVersion = "22.05";
}
