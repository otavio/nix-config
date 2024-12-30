{ pkgs }:

{
  base16-shell = pkgs.callPackage ./base16-shell { };
  bitbake-completion = pkgs.callPackage ./bitbake-completion { };
  kube-ps1 = pkgs.callPackage ./kube-ps1 { };
  ossystems-tools = pkgs.callPackage ./ossystems-tools { };
  patman = pkgs.callPackage ./patman { };
}
