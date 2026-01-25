{ pkgs, ...}:
{
  home.packages = [ 
  pkgs.kitty 
  pkgs.zellij
  pkgs.fastfetch
    ];
}
