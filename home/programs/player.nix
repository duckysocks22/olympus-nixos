{ pkgs, ...}:
{
  home.packages = with pkgs; [
    vlc
    jellyfin-desktop
    feishin
  ];
}
