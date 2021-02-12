{ pkgs, ... }:
{
  programs.firefox = {
    enable = true;

    profiles = {
      otavio = {
        settings = {
          "browser.ctrlTab.recentlyUsedOrder" = true;
        };
      };
    };
  };
}
