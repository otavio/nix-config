{ pkgs, ... }:

{

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
  };

  programs.gpg.enable = true;
}
