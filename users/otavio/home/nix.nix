{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ nixpkgs-fmt rnix-lsp ];
}
