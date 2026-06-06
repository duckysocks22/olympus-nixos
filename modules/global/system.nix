{ pkgs, config, ...}:
{

  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.tuned.enable = true;
  services.upower.enable = true;
  programs.zsh.enable = true;

  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    kernelModules = [ "sg" ];
    kernelParams = [ "amd_iommu=on" ];
    loader = {
      limine = {
        enable = true;
        secureBoot.enable = false;
        efiInstallAsRemovable = true;
      };
      efi = {
        canTouchEfiVariables = false;
      };
    };
  };

  environment.systemPackages = [
    pkgs.gptfdisk
    pkgs.gparted
    pkgs.xfsprogs
    pkgs.cifs-utils
    pkgs.nix-prefetch-git
    #pkgs.neovim
    pkgs.curl
    pkgs.torrent7z
    pkgs.python3
    pkgs.mktorrent
    pkgs.bashmount
    pkgs.qt6.qtbase
    pkgs.qt6.qtwayland
    pkgs.qt6.qttools
    pkgs.glibc
    pkgs.fontconfig
    pkgs.dbus
    pkgs.gsettings-desktop-schemas
    pkgs.gtk3
    pkgs.tpm2-tss
  ];

  environment.sessionVariables.XDG_DATA_DIRS = [
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
    "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
  ];

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;

  security.pam.services.niri.enableGnomeKeyring = true;

  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';

  security.sudo.extraRules = [
    {
      users = [ "foxtrot" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  services.thelounge.enable = true;

  services.udev.extraRules = ''
    # Finalmouse ULX devices - USB access
    SUBSYSTEM=="usb", ATTR{idVendor}=="361d", ATTR{idProduct}=="0100", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="361d", ATTR{idProduct}=="0101", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="361d", ATTR{idProduct}=="0102", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="361d", ATTR{idProduct}=="0103", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="361d", ATTR{idProduct}=="0104", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="361d", ATTR{idProduct}=="0111", MODE="0660", TAG+="uaccess"

    # Finalmouse ULX devices - HID access
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0100", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0101", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0102", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0104", MODE="0660", TAG+="uaccess"

    # Finalmouse Centerpiece Pro devices - USB access
    SUBSYSTEM=="usb", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0200", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0201", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0202", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0203", MODE="0660", TAG+="uaccess"

    # Finalmouse Centerpiece Pro devices - HID access
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0200", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0201", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0202", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="361d", ATTRS{idProduct}=="0203", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1fc9", ATTRS{idProduct}=="0021", MODE="0660", TAG+="uaccess"
  '';

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
