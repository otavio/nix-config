{ pkgs }:
{
  patman = pkgs.callPackage ./patman { };
  kube-ps1 = pkgs.callPackage ./kube-ps1 { };
  pa-applet = pkgs.callPackage ./pa-applet { };
}
