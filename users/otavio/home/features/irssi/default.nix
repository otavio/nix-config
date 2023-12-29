{ pkgs, ... }:

let
  irssi = pkgs.writeShellApplication {
    name = "irssi";
    runtimeInputs = [ pkgs.sops pkgs.irssi ];
    text = ''
      LIBERACHAT_PASSWORD=$(sops --decrypt --extract '["irssi-nickserv"]' "$HOME"/src/nix-config/secrets/secrets.yaml)
      export LIBERACHAT_PASSWORD
      irssi
    '';
  };
in
{
  home.packages = [ irssi ];

  home.file.".irssi" = {
    source = ./config;
    recursive = true;
  };
}
