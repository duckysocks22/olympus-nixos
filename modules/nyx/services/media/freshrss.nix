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

  services.nginx.virtualHosts."freshrss" = {
    listen = [{ addr = "127.0.0.1"; port = 8082; ssl = false; }];
  };

  services.rsshub = {
    enable = true;
    settings = {
      LISTEN_INADDR_ANY = true;
      PORT =  1200;
    };
    redis.enable = true;
  };

  networking.firewall.allowedTCPPorts = [ 1200 ];
}
