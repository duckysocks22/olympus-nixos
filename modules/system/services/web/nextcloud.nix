{ inputs, ... }:
{
  flake.nixosModules.nextcloud =
    {
      config,
      pkgs,
      ...
    }:
    {
      services.netcloud = {
        enable = true;
        pacakge = pkgs.nextcloud35;
        hostName = "next.olympus.moe";
        https = true;

        config = {
          adminuser = "foxtrot";
          adminpassFile = config.sops.secrets."nextcloud/adminpass".path;
          dbtype = "sqlite";

          settings = {
            maintenance_window_start = 1;
            default_phone_region = "US";
            log_type = "systemd";
            serverid = 0;
          };

          extraAppsEnable = true;
          extraApps = {
            inherit (config.services.nextcloud.package.packages.apps)
              new
              contacts
              calendar
              tasks
              ;
          };
        };
      };

      systemd.services.nextcloud-custom-config = {
        path = [ config.services.nextcloud.occ ];
        after = [ "nextcloud-setup.service" ];
        wantedBy = [ "multi-user.target" ];

        script = ''
          nextcloud-occ theming:config name "Olympus Cloud"
          nextcloud-occ theming:config url "https://cloud.olympus.moe";
          nextcloud-occ theming:config color "#3253a5";
        '';
      };

      sops.secrets."nextcloud/admin/pass" = { };
    };
}
