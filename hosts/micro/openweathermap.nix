{ config, ... }:

{
  sops.secrets."openweathermap/api-key" = {
    owner = config.users.users.otavio.name;
    inherit (config.users.users.otavio) group;
  };
}
