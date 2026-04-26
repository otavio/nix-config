{ config, ... }:

{
  sops.secrets."openai_api_key" = {
    owner = config.users.users.otavio.name;
    inherit (config.users.users.otavio) group;
  };

  hardware.uinput.enable = true;
  users.users.otavio.extraGroups = [ "uinput" ];
}
