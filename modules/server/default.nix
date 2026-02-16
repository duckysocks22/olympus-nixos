{ ... }:
{
  imports = [
    ./services/jellyfin.nix
    ./services/qbittorrent.nix
    ../functions.nix
    ./services/samba.nix
    ./nvidia.nix
    ./packages.nix
    ./services/frigate.nix
    ./services/adguardhome.nix
    ./services/navidrome.nix
    ../xfce/default.nix
    ./services/x2go.nix
    ./services/dawarich.nix
    ./services/avahi.nix
    ./services/minecraft.nix
  ];
}
