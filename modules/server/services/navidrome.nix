{ lib, ...}:
{
  services.navidrome = {
    enable = true;
    settings = {
      Address = "0.0.0.0";
      Port = 4533;
      MusicFolder = "/media/hdd1/music";
      EnableSharing = true;
      openFirewall = true;
      ND_LASTFM_APIKEY = "81dd1933879c04c5b933470fde4c3f7f";
      # No i do not care im sharing this secret
      ND_LASTFM_SECRET = "4ed0d1c9dbf1dc1a6a560dcf88c8f0e3";
    };
  };
  systemd.services.navidrome.serviceConfig.ProtectHome = lib.mkForce "read-only";

  #https://github.com/NixOS/nixpkgs/issues/481611
  nixpkgs.overlays = [
    (self: super: {
      navidrome = super.navidrome.overrideAttrs (oldAttrs: {
        CGO_CFLAGS_ALLOW = "--define-prefix";
      });
    })
  ];
  # ---------------------------------------------
}
