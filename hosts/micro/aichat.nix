{ config, pkgs, ... }:

{
  sops.secrets = {
    "openapi" = {
      owner = config.users.users.otavio.name;
      inherit (config.users.users.otavio) group;
    };
  };

  environment.systemPackages = with pkgs; [
    (writeScriptBin "aichat" "AICHAT_API_KEY=$(cat ${config.sops.secrets."openapi".path}) ${aichat}/bin/aichat")
  ];
}
