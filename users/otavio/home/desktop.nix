{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    anydesk
    gthumb
    nixpkgs-fmt
    nixpkgs-review
  ];

  programs.brave.enable = true;
}
