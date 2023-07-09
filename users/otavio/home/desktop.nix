{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    gthumb
    nixpkgs-fmt
    nixpkgs-review
  ];

  programs.brave.enable = true;
}
