{ config, ... }:

{
  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0525", ATTRS{idProduct}=="a4a6", GROUP="users", MODE="0660"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0525", ATTRS{idProduct}=="04a7", GROUP="users", MODE="0660"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2fe7", ATTRS{idProduct}=="0001", GROUP="users", MODE="0660"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0b1b", ATTRS{idProduct}=="0110", GROUP="users", MODE="0660"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0b1b", ATTRS{idProduct}=="0109", GROUP="users", MODE="0660"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0b1b", ATTRS{idProduct}=="0108", GROUP="users", MODE="0660"

    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2fe7", ATTRS{idProduct}=="f001", GROUP="users", MODE="0660"
  '';
}
