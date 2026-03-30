{ pkgs, inputs, ... }:
pkgs.mkShell {
  buildInputs = [
    inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena
    pkgs.home-manager
    pkgs.sops
  ];
}
