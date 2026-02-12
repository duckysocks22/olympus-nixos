{ pkgs, ...}:
{
  
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.tuned.enable = true;
  services.upower.enable = true;
  programs.zsh.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_zen;

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
  ];

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;

  security.pam.services.niri.enableGnomeKeyring = true;

  services.thelounge.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
