{
  services.zerotierone = {
    enable = true;
    joinNetworks = [
      # O.S. Systems
      "5e6f75af38d42102"
    ];
  };

  systemd.services.zerotierone-dns = {
    after = [ "sys-devices-virtual-net-zt6fl2ddr2.device" ];
    bindsTo = [ "sys-devices-virtual-net-zt6fl2ddr2.device" ];
    wantedBy = [ "sys-devices-virtual-net-zt6fl2ddr2.device" ];
    description = "zerotier dns";
    serviceConfig = {
      RemainAfterExit = true;
      ExecStart = ''
        resolvectl dns    zt6fl2ddr2 10.5.1.254
        resolvectl domain zt6fl2ddr2 "~lab.ossystems"
        resolvectl dnssec zt6fl2ddr2 false
      '';
    };
  };
}
