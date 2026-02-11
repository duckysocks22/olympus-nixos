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
