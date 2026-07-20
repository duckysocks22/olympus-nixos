{ config, ... }:
{
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    key = "${config.sops.secrets."syncthing/nyx/cert".path}";
    cert = "${config.sops.secrets."syncthing/nyx/key".path}";
    settings = {
      gui.user = "foxtrot";
      guiPasswordFile = "${config.sops.secrets."admin/pass".path}";

      folders = {
        "ffxivConfig" = {
          path = "/media/hdd1/services/syncthing";
          devices = [ ];
          ignorePerms = true;
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 8384 ];
}
