{ pkgs }:
{
  base16-shell = pkgs.callPackage ./base16-shell { };
  bitbake-completion = pkgs.callPackage ./bitbake-completion { };
  mods = pkgs.callPackage ./mods { };
  kube-ps1 = pkgs.callPackage ./kube-ps1 { };
  pa-applet = pkgs.callPackage ./pa-applet { };
  patman = pkgs.callPackage ./patman { };
}
