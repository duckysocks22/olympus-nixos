{ ... }:
{
  imports = [
    ./services/jellyfin.nix
    ./services/qbittorrent.nix
    ../functions.nix
    #./services/samba.nix
    ./nvidia.nix
    ./packages.nix
    ./services/frigate.nix
    ./services/adguardhome.nix
    ./services/navidrome.nix
    #../xfce/default.nix
    #./services/x2go.nix
    #./services/dawarich.nix
    ./services/avahi.nix
    ./services/game-servers/minecraft.nix
    ./services/homeassistant/default.nix
    ./services/copyparty.nix
    ./services/docker.nix
    ./services/mosquitto.nix
    ../power/disable-shutdown.nix
    #./services/web/default.nix
  ];
}
