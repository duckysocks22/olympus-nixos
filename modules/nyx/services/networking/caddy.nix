{ config, pkgs, ...}:
let
  puppygirls = pkgs.callPackage ../web/puppygirls {};
in
{
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/bunny@v1.2.0" ];
      hash = "sha256-7zkLy71J5D/J0LH/lyqVpWtrY7XSSrgYbWzaa3Ns2dc=";
    };
    environmentFile = "${config.sops.secrets."caddy/environment".path}";
    extraConfig = ''
      (mtls) {
        tls {
          client_auth {
            mode require_and_verify
            trust_pool file {
              pem_file /media/hdd1/certs/ca-cert.pem
            }
          }
        }
      }
    '';
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
      reverse_proxy /dns-query* 127.0.0.1:854 {
        header_up X-Real-IP {remote_host}
        transport http {
          tls_insecure_skip_verify
        }
      }

      tls {
        dns bunny {$BUNNY_API}
      }
    '';
    virtualHosts."https://budget.puppygirls.net".extraConfig = ''
      encode gzip zstd
      reverse_proxy :5006 {
        transport http {
          tls_server_name budget.puppygirls.net
        }
      }
      import mtls
    '';
    virtualHosts."http://stream.puppygirls.net, https://stream.puppygirls.net".extraConfig = ''
      reverse_proxy :8096

      tls {
        dns bunny {$BUNNY_API}
      }
    '';
    virtualHosts."http://music.puppygirls.net, https://music.puppygirls.net".extraConfig = ''
      reverse_proxy :4533

      tls {
        dns bunny {$BUNNY_API}
      }
    '';
    virtualHosts."http://audio.puppygirls.net, https://audio.puppygirls.net".extraConfig = ''
      reverse_proxy :8000

      tls {
        dns bunny {$BUNNY_API}
      }
    '';
    virtualHosts."https://immich.puppygirls.net".extraConfig = ''
      import mtls
      reverse_proxy :2283
    '';
    virtualHosts."https://ofsm.puppygirls.net".extraConfig = ''
      import mtls
      reverse_proxy :42702
    '';
    virtualHosts."https://ai.puppygirls.net".extraConfig = ''
      import mtls
      reverse_proxy :11435
    '';
    virtualHosts."https://home.puppygirls.net".extraConfig = ''
      import mtls
      reverse_proxy :8123
    '';
    virtualHosts."https://crafty.puppygirls.net".extraConfig = ''
      import mtls
      reverse_proxy :8443 {
        header_up Host {host}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
        flush_interval -1
        transport http {
          tls_insecure_skip_verify
          versions 1.1
        }
      }
    '';

    #olympus.moe
    virtualHosts."https://copy.olympus.moe".extraConfig = ''
      import mtls
      reverse_proxy :3210
    '';
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
