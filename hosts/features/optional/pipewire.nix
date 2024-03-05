{ pkgs, ... }:

{
  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber = {
      enable = true;
      configPackages = [
        (pkgs.writeTextDir "share/wireplumber/bluetooth.lua.d/51-bluez-config.lua" ''
          bluez_monitor.properties = {
            ["bluez5.enable-sbc-xq"]    = true,
            ["bluez5.enable-msbc"]      = true,
            ["bluez5.enable-hw-volume"] = true,
            ["bluez5.headset-roles"]    = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
          }
        '')
      ];
    };
  };
}
