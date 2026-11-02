{ pkgs, ... }:

let
  browser = pkgs.t3code-chrome-headless-shell;
in
{
  home = {
    packages = [ pkgs.t3code ];
    # T3 skips its own download when this path holds an executable browser.
    file.".t3/tools/chrome-headless-shell/${browser.platform}/${browser.version}".source = browser;
  };
}
