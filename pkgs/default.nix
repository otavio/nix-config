{ pkgs }:
{
  base16-shell = pkgs.callPackage ./base16-shell { };
  bitbake-completion = pkgs.callPackage ./bitbake-completion { };
  kube-ps1 = pkgs.callPackage ./kube-ps1 { };
  pa-applet = pkgs.callPackage ./pa-applet { };
  patman = pkgs.callPackage ./patman { };
}
