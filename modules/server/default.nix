{ ... }:
{
  imports = [
    ./services/jellyfin.nix
    ./services/qbittorrent.nix
    ../functions.nix
    ./services/samba.nix
    ./nvidia.nix
    #./services/frigate.nix
  ];
}
