{ inputs, self, ... }:
{
  flake.nixosModules.finalMouse =
    {
      ...
    }:
    {
      services.udev.extraRules = ''
        # Finalmouse ULX devices - USB access
        SUBSYSTEM=="usb", ATTR{idVendor}=="361d", ATTR{idProduct}=="0100", MODE="0660", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTR{idVendor}=="361d", ATTR{idProduct}=="0101", MODE="0660", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTR{idVendor}=="361d", ATTR{idProduct}=="0102", MODE="0660", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTR{idVendor}=="361d", ATTR{idProduct}=="0103", MODE="0660", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTR{idVendor}=="361d", ATTR{idProduct}=="0104", MODE="0660", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTR{idVendor}=="361d", ATTR{idProduct}=="0111", MODE="0660", TAG+="uaccess"

        # Finalmouse ULX devices - HID access
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0100", MODE="0660", GROUP="input", TAG+="uaccess"
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0101", MODE="0660", GROUP="input", TAG+="uaccess"
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0102", MODE="0660", GROUP="input", TAG+="uaccess"
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0104", MODE="0660", GROUP="input", TAG+="uaccess"

        # Finalmouse Centerpiece Pro devices - USB access
        SUBSYSTEM=="usb", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0200", MODE="0660", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0201", MODE="0660", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0202", MODE="0660", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0203", MODE="0660", TAG+="uaccess"

        # Finalmouse Centerpiece Pro devices - HID access
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0200", MODE="0660", GROUP="input", TAG+="uaccess"
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0201", MODE="0660", GROUP="input", TAG+="uaccess"
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0202", MODE="0660", GROUP="input", TAG+="uaccess"
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0203", MODE="0660", GROUP="input", TAG+="uaccess"
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1fc9", ATTRS{idProduct}=="0021", MODE="0660", GROUP="input", TAG+="uaccess"
      '';
    };
}
