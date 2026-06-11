{ inputs, pkgs, ... }:

let
  ossystems-scripts = pkgs.stdenv.mkDerivation {
    name = "ossystems-scripts";
    src = ./scripts;
    installPhase = ''
      mkdir -p $out/bin
      cp -r * $out/bin
    '';
  };

  # oe-ws calls these directly (repo init/sync inline, herdr/jq/fzf throughout),
  # so wrap it with them on PATH instead of relying on the ambient profile.
  oe-ws = pkgs.runCommandLocal "oe-ws"
    {
      nativeBuildInputs = [ pkgs.makeWrapper ];
    } ''
    install -Dm755 ${./oe-ws} $out/bin/oe-ws
    wrapProgram $out/bin/oe-ws \
      --prefix PATH : ${pkgs.lib.makeBinPath [
        inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
        pkgs.jq
        pkgs.fzf
        pkgs.gitRepo
      ]}
  '';
in
{
  nixpkgs.config.permittedInsecurePackages =
    # Issue: https://github.com/NixOS/nixpkgs/issues/273611
    pkgs.lib.optional (pkgs.obsidian.version == "1.5.3") "electron-25.9.0";

  home.packages = with pkgs; [
    awscli2
    obsidian
    oe-ws
  ];

  home.file = {
    ".yocto/site.conf".source = ./yocto-site.conf;
  };

  programs.zsh.initContent = ''
    export PATH=$PATH:${pkgs.lib.makeBinPath [ ossystems-scripts ]}
  '';
}
