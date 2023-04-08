{ config, pkgs, ... }:
{
  imports = [
    ./restic.nix
  ];

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
