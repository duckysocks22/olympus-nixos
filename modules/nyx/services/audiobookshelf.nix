{ pkgs-unstable, ... }:
{
  services.audiobookshelf = {
    enable = true;
    package = pkgs-unstable.audiobookshelf;
    openFirewall = true;
    user = "server";
    host = "0.0.0.0";
    #dataDir = "/media/hdd1/audio/podcasts";
  };
}
