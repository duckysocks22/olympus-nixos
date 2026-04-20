{ config, pkgs, ...}:
let
  puppygirls = pkgs.callPackage ../web/puppygirls {};
in
{
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/bunny@v1.2.0" ];
      hash = "sha256-s6Iin6ZaY6ius1+6OmwmLw26x1xszBPsEUjRzPAib4A=";
    };
    environmentFile = "${config.sops.secrets."caddy/environment".path}";
    virtualHosts."puppygirls.net, www.puppygirls.net".extraConfig = ''
      root * ${puppygirls}
      file_server {
        precompressed br gzip
      }

      tls {
        dns bunny {$BUNNY_API}
      }

    '';
    virtualHosts."http://cache.puppygirls.net, https://cache.puppygirls.net".extraConfig = ''
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
    virtualHosts."http://dns.puppygirls.net, https://dns.puppygirls.net".extraConfig = ''
      reverse_proxy :854 {
        
      }
    '';
    virtualHosts."http://budget.puppygirls.net, https://budget.puppygirls.net".extraConfig = ''
      encode gzip zstd
      reverse_proxy :5006 {
        transport http {
          tls_server_name budget.puppygirls.net
        }
      }

      tls {
        dns bunny {$BUNNY_API}
      }
    '';
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
