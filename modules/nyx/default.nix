{ pkgs, ... }:
let
  crafty-controller = pkgs.callPackage ../packages/crafty-controller.nix;
in
{
  imports = [
    ./power.nix
    ./services/jellyfin.nix
    ./services/qbittorrent.nix
    ./services/ssh-tunnel.nix
    ../global/functions.nix
    #./services/samba.nix
    ./nvidia.nix
    ./packages.nix
    #./services/frigate.nix
    ./services/navidrome.nix
    ./services/audiobookshelf.nix
    ./services/yt-dlp/default.nix
    ./services/networking/default.nix
    ./services/attic.nix
    ./services/printing.nix
    ./services/forgejo-runner/forgejo-runner.nix
    #../xfce/default.nix
    #./services/x2go.nix
    #./services/dawarich.nix
    ./services/game-servers/minecraft.nix
    ./services/game-servers/factorio.nix
    ./services/homeassistant/default.nix
    ./services/copyparty.nix
    ./services/docker.nix
    ./services/mosquitto.nix
    ../global/power/disable-shutdown.nix
    #./services/web/default.nix
    ./services/samba/samba.nix
    ./services/actual-finance/actual-server.nix
    ./services/immich.nix
    #./services/ollama.nix
  ];

  environment.systemPackages = [
    crafty-controller
  ];
}
