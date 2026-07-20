{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kitty
    zellij
    fastfetch
    #xfce.thunar // Issues viewing fileshare
    kdePackages.dolphin
    unrar
    p7zip
    (bottles.override {
      removeWarningPopup = true;
    })
    libreoffice-qt-fresh
    wine
    winetricks
    protontricks
    remmina
    filezilla
    feather
  ];

  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
    };
  };
}
