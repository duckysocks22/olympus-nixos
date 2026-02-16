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
    ./services/owntracks.nix
    ./services/minecraft.nix
  ];
}
