{ config, pkgs, ... }:
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
}
