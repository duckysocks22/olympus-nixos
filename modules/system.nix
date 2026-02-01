{ pkgs, ...}:
{
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.tuned.enable = true;
  services.upower.enable = true;
  programs.zsh.enable = true;

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
  ];

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;

  security.pam.services.niri.enableGnomeKeyring = true;
}
