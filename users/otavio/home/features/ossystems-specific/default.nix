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
  nixpkgs.config.permittedInsecurePackages =
    # Issue: https://github.com/NixOS/nixpkgs/issues/273611
    pkgs.lib.optional (pkgs.obsidian.version == "1.4.16") "electron-25.9.0";

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
