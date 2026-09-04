{ config, ... }:
{
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    key = "${config.sops.secrets."syncthing/circe/key".path}";
    cert = "${config.sops.secrets."syncthing/circe/cert".path}";
    settings = {
      devices = {

      };

      folders = {
        "ffxivConfig" = {
          path = "/home/foxtrot/.xlcore/ffxivConfig/";
          ignorePerms = true;
        };
      };
    };
  };
}
