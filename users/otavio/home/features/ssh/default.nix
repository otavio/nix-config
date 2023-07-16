_:

{
  programs.ssh = {
    enable = true;

    controlMaster = "auto";
    hashKnownHosts = false;

    extraConfig = ''
      Host code.ossystems.com.br
           HostName code.ossystems.io

      Host *.lab.ossystems
           ForwardAgent yes
           ForwardX11 yes
           ForwardX11Trusted yes
    '';
  };
}
