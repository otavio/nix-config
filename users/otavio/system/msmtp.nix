{ config, ... }:

{
  sops.secrets = {
    "msmtp/password" = { };
  };

  programs = {
    msmtp = {
      enable = true;

      accounts = {
        "default" = {
          tls = true;
          host = "smtp.gmail.com";
          port = 587;
          auth = true;
          from = "otavio.salvador@gmail.com";
          user = "otavio.salvador";
          passwordeval = "cat ${config.sops.secrets."msmtp/password".path}";
        };
      };
    };
  };
}
