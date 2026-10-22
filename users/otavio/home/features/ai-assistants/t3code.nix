{ pkgs, ... }:

let
  browser = pkgs.callPackage ./chrome-headless-shell.nix { };
in
{
  home = {
    packages = [ pkgs.t3code ];
    # T3 skips its own download when this path holds an executable browser.
    file.".t3/tools/chrome-headless-shell/${browser.platform}/${browser.version}".source = browser;
  };
}
