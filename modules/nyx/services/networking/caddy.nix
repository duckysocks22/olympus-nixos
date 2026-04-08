{ config, pkgs, ...}:
{
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/bunny@v1.2.0" ];
      hash = "sha256-s6Iin6ZaY6ius1+6OmwmLw26x1xszBPsEUjRzPAib4A=";
    };
    globalConfig = ''
      servers {
        protocols h1
      }
    '';
    environmentFile = "${config.sops.secrets."caddy/environment".path}";
    virtualHosts."https://www.puppygirls.net".extraConfig = ''
      reverse_proxy :443 {
        header_up Host {upstream_hostport}
      }
    '';
    virtualHosts."https://cache.puppygirls.net".extraConfig = ''
      reverse_proxy :7989 {
        header_up Host {upstream_hostport}
        flush_interval -1

        transport http {
          versions 1.1
        }
      }
      tls {
        dns bunny {$BUNNY_API}
      }
    '';
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
