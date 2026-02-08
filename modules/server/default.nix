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
  ];
}
