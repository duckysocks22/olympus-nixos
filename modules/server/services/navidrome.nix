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
}
