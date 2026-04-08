{ ... }:
{
  imports = [
    ./services/jellyfin.nix
    ./services/qbittorrent.nix
    ../global/functions.nix
    #./services/samba.nix
    ./nvidia.nix
    ./packages.nix
    #./services/frigate.nix
    ./services/navidrome.nix
    ./services/networking/default.nix
    ./services/attic.nix
    ./services/printing.nix
    ./services/forgejo-runner/forgejo-runner.nix
    #../xfce/default.nix
    #./services/x2go.nix
    #./services/dawarich.nix
    ./services/game-servers/minecraft.nix
    ./services/homeassistant/default.nix
    ./services/copyparty.nix
    ./services/docker.nix
    ./services/mosquitto.nix
    ../global/power/disable-shutdown.nix
    #./services/web/default.nix
    ./services/samba/samba.nix
  ];
}
