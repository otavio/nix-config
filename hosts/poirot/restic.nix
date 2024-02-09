{ config, ... }:

{
  sops.secrets = {
    "backup/credentials" = { };
    "backup/repository" = { };
    "backup/password" = { };
  };

  services.restic.backups = {
    wasabi = {
      user = "root";
      initialize = true;

      environmentFile = config.sops.secrets."backup/credentials".path;
      repositoryFile = config.sops.secrets."backup/repository".path;
      passwordFile = config.sops.secrets."backup/password".path;

      paths = [ config.users.users.bruna.home ];

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
        "--keep-yearly 0"
      ];

      extraBackupArgs = [
        "--exclude-caches"
        "--exclude-if-present .backup-ignore"
      ];
    };
  };
}
