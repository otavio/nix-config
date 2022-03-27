{ config, pkgs, ... }:
let
  homeDirectory = "/home/bruna";
in
{
  users.users.bruna = {
    description = "Bruna C. Tessmer Salvador";

    isNormalUser = true;
    extraGroups = [
      "lp"
      "networkmanager"
      "scanner"
      "wheel"
    ];

    uid = 1002;

    # Default - used for bootstrapping.
    password = "pw";
  };

  sops.secrets = {
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
        "--exclude-caches"
        "--exclude-if-present .backup-ignore"
      ];
    };
  };
}
