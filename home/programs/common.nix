{ pkgs, ...}:
{
  home.packages = [ 
  pkgs.kitty 
  pkgs.zellij
  pkgs.fastfetch
  pkgs.xfce.thunar
  pkgs.bottles
  ];

  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
    };
  };
}
