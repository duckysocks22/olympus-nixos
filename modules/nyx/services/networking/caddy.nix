{ config, pkgs, ... }:
let
  puppygirls = pkgs.callPackage ../web/puppygirls { };
in
{
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/bunny@v1.2.0" ];
      hash = "sha256-4KUrAAjsDP2siy0Cdjvjd62FjWBxPy4U4V4xe/Gqa3s=";
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
    virtualHosts."http://stream.puppygirls.net, https://stream.puppygirls.net".extraConfig = ''
      reverse_proxy :8096 {
        header_up Host {host}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
        flush_interval -1
      }

      tls {
        dns bunny {$BUNNY_API}
      }
    '';
    virtualHosts."https://seerr.puppygirls.net".extraConfig = ''
      header Access-Control-Allow-Origin "https://stream.puppygirls.net"
      header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
      header Access-Control-Allow-Headers "Content-Type, Authorization, X-Api-Key"
      header Access-Control-Allow-Credentials "true"

      @options method OPTIONS
      respond @options 204

      reverse_proxy :5055 {
        header_up X-Real-IP {remote_host}
      }

      tls {
        dns bunny {$BUNNY_API}
      }
    '';
    virtualHosts."https://radarr.puppygirls.net".extraConfig = ''
      header Access-Control-Allow-Origin "https://stream.puppygirls.net"
      header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
      header Access-Control-Allow-Headers "Content-Type, Authorization, X-Api-Key"
      header Access-Control-Allow-Credentials "true"

      @options method OPTIONS
      respond @options 204

      reverse_proxy :5056 {
        header_up X-Real-IP {remote_host}
        transport http {
          versions 1.1
        }
      }
    '';
    virtualHosts."https://sonarr.puppygirls.net".extraConfig = ''
      header Access-Control-Allow-Origin "https://stream.puppygirls.net"
      header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
      header Access-Control-Allow-Headers "Content-Type, Authorization, X-Api-Key"
      header Access-Control-Allow-Credentials "true"

      @options method OPTIONS
      respond @options 204

      reverse_proxy :5057 {
        header_up X-Real-IP {remote_host}
        transport http {
          versions 1.1
        }
      }
    '';
    virtualHosts."https://prowlarr.puppygirls.net".extraConfig = ''
      header Access-Control-Allow-Origin "https://stream.puppygirls.net"
      header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
      header Access-Control-Allow-Headers "Content-Type, Authorization, X-Api-Key"
      header Access-Control-Allow-Credentials "true"

      @options method OPTIONS
      respond @options 204

      reverse_proxy :5058 {
        header_up X-Real-IP {remote_host}
        transport http {
          versions 1.1
        }
      }
    '';
    virtualHosts."https://tdarr.puppygirls.net".extraConfig = ''
      header Access-Control-Allow-Origin "https://stream.puppygirls.net"
      header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
      header Access-Control-Allow-Headers "Content-Type, Authorization, X-Api-Key"
      header Access-Control-Allow-Credentials "true"

      @options method OPTIONS
      respond @options 204

      reverse_proxy :5059 {
        header_up X-Real-IP {remote_host}
        transport http {
          versions 1.1
        }
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
    virtualHosts."https://ofsm.puppygirls.net".extraConfig = ''
      import mtls
      reverse_proxy :42702
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
    virtualHosts."https://rss.olympus.moe".extraConfig = ''
      import mtls
      reverse_proxy :8082

      tls {
        dns bunny {$BUNNY_API}
      }
    '';
    virtualHosts."https://rsshub.olympus.moe".extraConfig = ''
      reverse_proxy :1200

      tls {
        dns bunny {$BUNNY_API}
      }
    '';
    virtualHosts."https://copy.olympus.moe".extraConfig = ''
      import mtls

      @mkcol_phonebackup {
        method MKCOL
        path /phonebackup/*
      }

      reverse_proxy @mkcol_phonebackup :3210 {
        header_up X-Forwarded-For {remote_host}
        @exists status 405
        handle_response @exists {
          respond 201
        }
      }

      reverse_proxy :3210 {
        header_up X-Forwarded-For {remote_host}
      }

    '';
    virtualHosts."https://immich.olympus.moe".extraConfig = ''
      import mtls
      reverse_proxy :2283
    '';
    virtualHosts."https://home.olympus.moe".extraConfig = ''
      import mtls
      reverse_proxy :8123
    '';
    virtualHosts."https://budget.olympus.moe".extraConfig = ''
      encode gzip zstd
      reverse_proxy :5006 {
        transport http {
          tls_server_name budget.puppygirls.net
        }
      }
      import mtls
    '';
    virtualHosts."https://qbit.olympus.moe".extraConfig = ''
      encode gzip zstd
      reverse_proxy :8080

      import mtls
    '';
    virtualHosts."https://ntfy.olympus.moe".extraConfig = ''
      reverse_proxy :1147

      @httpget {
        protocol http
        method GET
        path_regexp ^/([-_a-z0-9]{0,64}$|docs/|static/)
      }
      redir @httpget https://{host}{uri}

      tls {
        dns bunny {$BUNNY_API}
      }
    '';
    virtualHosts."https://molly.olympus.moe".extraConfig = ''
      reverse_proxy :8020 {
        header_up Host {host}
      }

      tls {
        dns bunny {$BUNNY_API}
      }
    '';
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
