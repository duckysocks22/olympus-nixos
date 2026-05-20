{ config, lib, ... }:
{
  services.immich = {
    enable = true;
    host = "127.0.0.1";
    port = 2283;
    openFirewall = true;
    environment.IMMICH_LOG_LEVEL = "warn";

    machine-learning = {
      environment = {
        IMMICH_PORT = lib.mkForce "3004";
      };
    };

    mediaLocation = "/media/hdd1/media/immich/";
    secretsFile = "${config.sops.secrets."immich/secrets".path}";
  };
}
