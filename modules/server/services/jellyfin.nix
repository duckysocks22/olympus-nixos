{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    jellyfin
    jellyfin-web
    ffmpeg
  ];
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    dataDir = "/media/hdd1/jellyfin/media";
    configDir = "/media/hdd1/jellyfin/config";
  };
}
