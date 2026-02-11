{ pkgs, ...}:
{
  home.packages = with pkgs; [ 
    kitty 
    zellij
    fastfetch
    xfce.thunar
    vlc
    jellyfin-desktop
    unrar
    p7zip
    (bottles.override {
      removeWarningPopup = true;
    })
    libreoffice-qt-fresh
    wine
    winetricks
    protontricks
  ];

  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
    };
  };
}
