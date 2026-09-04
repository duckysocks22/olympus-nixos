{ config, ... }:
{
  services.mollysocket = {
    enable = true;
    settings = {
      host = "0.0.0.0";
      port = 8020;
      allowed_endpoints = [ "https://ntfy.olympus.moe" ];
      allowed_uuids = [ "a6be8ba5-eb84-42b9-a1f4-c22509904f61" ];
      vapid_key_file = "${config.sops.secrets."mollysocket/vapid_privkey".path}";
    };
  };

  systemd.services.mollysocket.serviceConfig = {
    User = "mollysocket";
  };

  users.users.mollysocket = {
    isSystemUser = true;
    group = "mollysocket";
  };

  users.groups.mollysocket = { };
}
