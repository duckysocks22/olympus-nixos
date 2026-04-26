{ lib, config, ...}:
{
  services.navidrome = {
    enable = true;
    environmentFile = "${config.sops.secrets."navidrome/environment".path}";
    settings = {
      Address = "0.0.0.0";
      Port = 4533;
      MusicFolder = "/media/hdd1/audio/music";
      AutoImportPlaylists = false;
      EnableSharing = true;
      openFirewall = true;
      AutoTranscodeDownload = true;
      Agents = "lastfm,deezer,listenbrains";
      LastFM.Enabled = true;
    };
  };
  systemd.services.navidrome.serviceConfig.ProtectHome = lib.mkForce "read-only";
}
