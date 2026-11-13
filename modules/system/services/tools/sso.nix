{ inputs, ... }:
{
  flake.nixosModules.sso =
    {
      config,
      pkgs,
      ...
    }:
    {
      services.pocket-id = {
        enable = true;
        user = "pocket-id";
        group = "pocket-id";
        package = pkgs.pocket-id;
        dataDir = "/media/hdd1/services/pocket-id";

        settings = {
          APP_URL = "https://sso.olympus.moe";
          TRUST_PROXY = true;
        };

        credentials = {
          ENCRYPTION_KEY = config.sops.secrets."pocket-id/encryption".path;
          MAXMIND_LICENSE_KEY = config.sops.secrets."pocket-id/maxmind".path;
        };
      };

      users.users.pocket-id = {
        isSystemUser = true;
        group = "pocket-id";
      };

      users.groups.pocket-id = { };
    };
}
