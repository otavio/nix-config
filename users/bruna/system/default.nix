{ pkgs, ... }:
let
  homeDirectory = "/home/bruna";
in
{
  users.users.bruna = {
    description = "Bruna C. Tessmer Salvador";

    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
    uid = 1002;

    # Default - used for bootstrapping.
    password = "pw";
  };

  services.restic.backups = {
    wasabi = {
      user = "bruna";
      repository = "s3:https://s3.ca-central-1.wasabisys.com:/backup-repository";

      initialize = true;

      # File with:
      # AWS_ACCESS_KEY_ID=<YOUR-WASABI-ACCESS-KEY-ID>
      # AWS_SECRET_ACCESS_KEY=<YOUR-WASABI-SECRET-ACCESS-KEY>
      environmentFile = "${homeDirectory}/.restic.credentials";

      # File with 'password'
      passwordFile = "${homeDirectory}/.restic.password";

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
        "--exclude-file=${homeDirectory}/tmp"
      ];
    };
  };
}
