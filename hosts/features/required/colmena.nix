{ config, lib, ... }:

{
  options.my.deployment = {
    targetHost = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = config.networking.hostName;
      description = "SSH host Colmena connects to. Null restricts this node to local deployment.";
    };

    targetPort = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.unsigned;
      default = null;
      description = "SSH port Colmena connects to, or null for the ssh_config default.";
    };

    targetUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "root";
      description = "User Colmena logs in as.";
    };

    buildOnTarget = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Build the system closure on the target rather than locally.";
    };

    allowLocalDeployment = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow `colmena apply-local` on this node.";
    };
  };

  config.my.deployment.targetUser = "otavio";
}
