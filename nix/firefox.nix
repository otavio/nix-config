{ pkgs, ... }:
let
  nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
    inherit pkgs;
  };
in
{
  programs.firefox = {
    enable = true;

    extensions = with nur.repos.rycee.firefox-addons; [
      lastpass-password-manager
      vimium
    ];

    profiles = {
      otavio = {
        settings = {
          "browser.ctrlTab.recentlyUsedOrder" = true;
        };
      };
    };
  };
}
