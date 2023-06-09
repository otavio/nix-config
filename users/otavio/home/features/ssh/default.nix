_:

{
  programs.ssh = {
    enable = true;

    controlMaster = "auto";
    hashKnownHosts = false;

    extraConfig = ''
      Host *.ossystems.com.br
           HostkeyAlgorithms +ssh-rsa
           PubkeyAcceptedAlgorithms +ssh-rsa

      Host *.lab.ossystems
           ForwardAgent yes
           ForwardX11 yes
           ForwardX11Trusted yes
    '';
  };
}
