{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        controlMaster = "auto";
        hashKnownHosts = false;
      };

      "code.ossystems.com.br" = {
        hostname = "code.ossystems.io";
      };

      "*.lab.ossystems" = {
        forwardAgent = true;
        forwardX11 = true;
        forwardX11Trusted = true;
      };

      "gitlab.com" = {
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}
