{ config, pkgs, ...}:
{
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/bunny@v1.2.0" ];
      hash = "sha256-s6Iin6ZaY6ius1+6OmwmLw26x1xszBPsEUjRzPAib4A=";
    };
    environmentFile = "${config.sops.secrets."caddy/environment".path}";
    virtualHosts."https://www.puppygirls.net".extraConfig = ''
      reverse_proxy https://localhost:443 {
        header_up Host {upstream_hostport}
      }
    '';
    virtualHosts."https://cache.puppygirls.net".extraConfig = ''
      reverse_proxy http://localhost:7989 {
        header_up Host {upstream_hostport}
      }
      tls {
        dns bunny {$BUNNY_API}
      }
    '';
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
