{ pkgs }:
{
  patman = pkgs.callPackage ./patman { };
  discord = pkgs.callPackage ./discord { };
}
