{ config, ... }:
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

  # Bind the nginx virtual host to localhost only on port 8082.
  # Caddy reverse-proxies from https://rss.olympus.moe → :8082.
  services.nginx.virtualHosts."freshrss" = {
    listen = [{ addr = "127.0.0.1"; port = 8082; ssl = false; }];
  };
}
