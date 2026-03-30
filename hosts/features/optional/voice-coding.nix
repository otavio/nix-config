{ ... }:

{
  # Udev rules for Talon voice coding (Tobii eye tracker support)
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2104", ATTRS{idProduct}=="0127", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2104", ATTRS{idProduct}=="0118", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2104", ATTRS{idProduct}=="0106", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2104", ATTRS{idProduct}=="0128", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2104", ATTRS{idProduct}=="010a", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2104", ATTRS{idProduct}=="0102", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2104", ATTRS{idProduct}=="0313", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2104", ATTRS{idProduct}=="0318", TAG+="uaccess"
  '';
}
