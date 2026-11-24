{ inputs, ... }:
{
  flake.nixosModules.freshrss =
    {
      config,
      lib,
      ...
    }:
    {
      services.freshrss = {
        enable = true;
        api.enable = true;
        webserver = "nginx";
        virtualHost = "freshrss";
        baseUrl = "https://rss.olympus.moe";
        defaultUser = "foxtrot";
        authType = "form";
        passwordFile = config.sops.secrets."media/freshrss".path;
      };

      services.nginx.virtualHosts."freshrss" = {
        listen = [
          {
            addr = "192.168.10.253";
            port = 8082;
            ssl = false;
          }
        ];
      };

      services.rsshub = {
        enable = true;
        settings = {
          LISTEN_INADDR_ANY = true;
          PORT = 1200;
        };
        redis.enable = true;
      };

      # php aborts on heap corruption while starting extensions (bcmath, curl,
      # dom, intl, mbstring, pdo, ...) under the allocator preloaded by
      # systemHarden, so mask the preload file out of these units' namespaces
      systemd.services =
        lib.genAttrs
          [
            "freshrss-config"
            "freshrss-updater"
            "phpfpm-freshrss"
          ]
          (_: {
            serviceConfig.BindReadOnlyPaths = [ "/dev/null:/etc/ld-nix.so.preload" ];
          });

      networking.firewall.allowedTCPPorts = [ 1200 ];
    };
}
