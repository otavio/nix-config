{ pkgs }:
{
  patman = pkgs.callPackage ./patman { };
  tmuxp = pkgs.callPackage ./tmuxp { };
  zsh-completions = pkgs.callPackage ./zsh-completions { };
}
