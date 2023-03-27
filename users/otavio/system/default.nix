{ config, pkgs, ... }:
let
  homeDirectory = "/home/otavio";
in
{
  programs = {
    zsh.enable = true;
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
          passwordeval = "cat ${config.sops.secrets.msmtp-password.path}";
        };
      };
    };
  };

  sops.secrets = {
    "msmtp-password" = { };
    "backup/credentials" = { };
    "backup/repository" = { };
    "backup/password" = { };
  };

  services.restic.backups = {
    wasabi = {
      user = "root";
      initialize = true;

      environmentFile = "${config.sops.secrets."backup/credentials".path}";
      repositoryFile = "${config.sops.secrets."backup/repository".path}";
      passwordFile = "${config.sops.secrets."backup/password".path}";

      paths = [ "${homeDirectory}" ];

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
        "--keep-yearly 3"
      ];

      extraBackupArgs = [
        "--exclude='.direnv'"
        "--exclude='target'"
        "--exclude='build*/**/tmp'"
        "--exclude-caches"
        "--exclude-if-present .backup-ignore"
      ];
    };
  };

  users.users.otavio = {
    description = "Otavio Salvador";

    isNormalUser = true;
    extraGroups = [ "wheel" ];
    uid = 1000;
    shell = pkgs.zsh;

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAu7exa84N7tURdEdgc7YRkxlouwrK3CbBsQh8cYIFsCwt+fd5cGzVWFMQ1ZIBo36HA9ocBGA7am4uQkBMrb5CSxpr5OGWmrPU0uE6aUtZedhdGj1f9gPJA8QeDfcYxFntQjD1f/XfprLkySD53z/w5npjquy2Y2zWrbOLyHSpU/M= otavio@server.casa.com.br"
    ];

    # Default - used for bootstrapping.
    password = "pw";
  };

  # In case if it's enabled, I should have access to use it.
  users.extraGroups.audio.members = [ "otavio" ];
  users.extraGroups.networkmanager.members = [ "otavio" ];
  users.extraGroups.docker.members = [ "otavio" ];
  users.extraGroups.libvirtd.members = [ "otavio" ];
}
