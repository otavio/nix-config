{
  services.zerotierone = {
    enable = true;
    joinNetworks = [
      # O.S. Systems
      "5e6f75af38d42102"

      # Salvador's Home
      "5e6f75af38991ce8"
    ];
  };

  systemd.services.zerotierone-dns = {
    after = [ "sys-devices-virtual-net-zt6fl2ddr2.device" "sys-devices-virtual-net-zt6fl6zm6q.device" ];
    bindsTo = [ "sys-devices-virtual-net-zt6fl2ddr2.device" "sys-devices-virtual-net-zt6fl6zm6q.device" ];
    wantedBy = [ "sys-devices-virtual-net-zt6fl2ddr2.device" "sys-devices-virtual-net-zt6fl6zm6q.device" ];
    description = "zerotier dns";
    serviceConfig = {
      RemainAfterExit = true;
      ExecStart = ''
        resolvectl dns    zt6fl2ddr2 10.5.1.254
        resolvectl domain zt6fl2ddr2 "~lab.ossystems"
        resolvectl dnssec zt6fl2ddr2 false

        resolvectl dns    zt6fl6zm6q 10.4.0.254
        resolvectl domain zt6fl6zm6q "~casa.salvador"
        resolvectl dnssec zt6fl6zm6q false
      '';
    };
  };
}
