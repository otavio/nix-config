{ pkgs, ... }:

let
  inherit (pkgs.t3code) browser;
in
{
  home.packages = [ pkgs.t3code ];

  # T3 skips its own download when this path holds an executable browser.
  home.file.".t3/tools/chrome-headless-shell/${browser.platform}/${browser.version}".source = browser;
}
