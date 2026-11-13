{ inputs, ... }:
{
  flake.nixosModules.navidrome =
    {
      config,
      lib,
      ...
    }:
    {
      services.navidrome = {
        enable = true;
        openFirewall = true;
        environmentFile = "${config.sops.secrets."navidrome/environment".path}";

        settings = {
          Address = "0.0.0.0";
          Port = 4533;
          MusicFolder = "/media/hdd1/audio/music";
          AutoImportPlaylists = false;
          EnableSharing = true;
          AutoTranscodeDownload = true;
          Agents = "lastfm,deezer,listenbrains";
          LastFM.Enabled = true;
        };
      };

      systemd.services.navidrome.serviceConfig.ProtectHome = lib.mkForce "read-only";

      # navidrome bind-mounts resolved's resolv.conf; during a switch it can
      # start before resolved has written that file
      systemd.services.navidrome.after = [ "systemd-resolved.service" ];
      systemd.services.navidrome.wants = [ "systemd-resolved.service" ];
    };
}
