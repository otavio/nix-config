{ pkgs, ... }:
{
  home.file = {
    ".gitconfig".source = ./git/config;
    ".gitaliases".source = ./git/aliases;
    ".patman".source = ./git/patman;
  };

  home.packages = with pkgs; [
    git
    git-review
    git-secret
    gitAndTools.delta
    gitRepo
    gh
    patman
  ];
}
