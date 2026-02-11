{ pkgs, ...}:
{
  home.packages = [ 
  pkgs.kitty 
  pkgs.zellij
  pkgs.fastfetch
  pkgs.xfce.thunar
  pkgs.vlc
  pkgs.jellyfin-desktop
  (pkgs.bottles.override {
    removeWarningPopup = true;
  })
  pkgs.libreoffice-qt-fresh
  ];

  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
    };
  };
}
