{ pkgs, ... }:

let
  ossystems-scripts = pkgs.stdenv.mkDerivation {
    name = "ossystems-scripts";
    src = ./scripts;
    installPhase = ''
      mkdir -p $out/bin
      cp -r * $out/bin
    '';
  };
in
{
  home.packages = with pkgs; [
    awscli2
    obsidian
    ossystems-tools
  ];

  home.file = {
    ".yocto/site.conf".source = ./yocto-site.conf;
  };

  programs.zsh = {
    initExtra = ''
      export PATH=$PATH:${pkgs.lib.makeBinPath [ ossystems-scripts ]}
    '';
  };
}
