{ inputs, self, ... }:
{
  flake.nixosModules.caddy =
    {
      config,
      pkgs,
      ...
    }:
    let
      puppygirls = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.puppygirls;
    in
    {
      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = [ "github.com/caddy-dns/bunny@v1.2.0" ];
          hash = "sha256-92prKdGudX4MAEfUjyCrtpWoy6p5rwYxEEDnzLg2fmI=";
        };
        environmentFile = "${config.sops.secrets."caddy/environment".path}";
        globalConfig = ''
          servers {
            timeouts {
              idle 15m
              read_body_idle 1h
              write_idle 1h
            }
          }
        '';
        extraConfig = ''
          (mtls) {
            tls {
              client_auth {
                mode require_and_verify
                trust_pool file {
                  pem_file ${config.sops.secrets."caddy/ca-cert".path}
                }
              }
            }
          }

          (bunny) {
            tls {
              dns bunny {$BUNNY_API}
            }
          }

          (arrcors) {
            header Access-Control-Allow-Origin "https://stream.puppygirls.net"
            header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
            header Access-Control-Allow-Headers "Content-Type, Authorization, X-Api-Key"
            header Access-Control-Allow-Credentials "true"

            @options method OPTIONS
            respond @options 204
          }
        '';
        virtualHosts."puppygirls.net, www.puppygirls.net".extraConfig = ''
          root * ${puppygirls}
          file_server {
            precompressed br gzip
          }

          import bunny

        '';
        virtualHosts."cache.puppygirls.net".extraConfig = ''
          reverse_proxy 127.0.0.1:7989 {
            header_up Host {upstream_hostport}
            flush_interval -1

            transport http {
              versions 1.1
            }
          }

          import bunny
        '';
        virtualHosts."dns.puppygirls.net".extraConfig = ''
          reverse_proxy /dns-query* 192.168.10.253:854 {
            header_up X-Real-IP {remote_host}
            transport http {
              tls_server_name dns.puppygirls.net
            }
          }

          import bunny
        '';
        virtualHosts."stream.puppygirls.net".extraConfig = ''
          reverse_proxy 127.0.0.1:8096 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
            flush_interval -1
          }

          import bunny
        '';
        virtualHosts."https://seerr.puppygirls.net".extraConfig = ''
          import mtls
          import arrcors

          reverse_proxy 127.0.0.1:5055 {
            header_up X-Real-IP {remote_host}
          }

          import bunny
        '';
        virtualHosts."https://radarr.puppygirls.net".extraConfig = ''
          import mtls
          import arrcors

          reverse_proxy 127.0.0.1:5056 {
            header_up X-Real-IP {remote_host}
            transport http {
              versions 1.1
            }
          }

          import bunny
        '';
        virtualHosts."https://sonarr.puppygirls.net".extraConfig = ''
          import mtls
          import arrcors

          reverse_proxy 127.0.0.1:5057 {
            header_up X-Real-IP {remote_host}
            transport http {
              versions 1.1
            }
          }

          import bunny
        '';
        virtualHosts."https://prowlarr.puppygirls.net".extraConfig = ''
          import mtls
          import arrcors

          reverse_proxy 127.0.0.1:5058 {
            header_up X-Real-IP {remote_host}
            transport http {
              versions 1.1
            }
          }

          import bunny
        '';
        virtualHosts."music.puppygirls.net".extraConfig = ''
          reverse_proxy 127.0.0.1:4533

          import bunny
        '';
        virtualHosts."audio.puppygirls.net".extraConfig = ''
          reverse_proxy 127.0.0.1:8000

          import bunny
        '';
        virtualHosts."https://ofsm.puppygirls.net".extraConfig = ''
          import mtls
          reverse_proxy 127.0.0.1:42702

          import bunny
        '';

        #olympus.moe
        virtualHosts."https://rss.olympus.moe".extraConfig = ''
          import mtls
          reverse_proxy 127.0.0.1:8082

          import bunny
        '';
        virtualHosts."https://rsshub.olympus.moe".extraConfig = ''
          import mtls

          reverse_proxy 127.0.0.1:1200

          import bunny
        '';
        virtualHosts."https://copy.olympus.moe".extraConfig = ''
          import mtls

          @mkcol_phonebackup {
            method MKCOL
            path /phonebackup/*
          }

          reverse_proxy @mkcol_phonebackup 192.168.10.253:3210 {
            header_up X-Forwarded-For {remote_host}
            @exists status 405
            handle_response @exists {
              respond 201
            }
          }

          reverse_proxy 127.0.0.1:3210 {
            header_up X-Forwarded-For {remote_host}
          }

          import bunny
        '';
        virtualHosts."https://immich.olympus.moe".extraConfig = ''
          import mtls
          reverse_proxy 127.0.0.1:2283

          import bunny
        '';
        virtualHosts."https://home.olympus.moe".extraConfig = ''
          import mtls
          reverse_proxy 127.0.0.1:8123

          import bunny
        '';
        virtualHosts."https://budget.olympus.moe".extraConfig = ''
          encode gzip zstd
          reverse_proxy 127.0.0.1:5006
          import mtls

          import bunny
        '';
        /*
          virtualHosts."https://qbit.olympus.moe".extraConfig = ''
            encode gzip zstd
            reverse_proxy 127.0.0.1:8080

            import mtls
          '';
        */
        virtualHosts."https://ntfy.olympus.moe".extraConfig = ''
          reverse_proxy 127.0.0.1:1147

          import bunny
        '';
        virtualHosts."https://molly.olympus.moe".extraConfig = ''
          reverse_proxy 127.0.0.1:8020 {
            header_up Host {host}
            header_up X-Original-URL {path}
          }

          import bunny
        '';
        virtualHosts."dash.olympus.moe".extraConfig = ''
          import mtls
          reverse_proxy 127.0.0.1:8085

          import bunny
        '';
        virtualHosts."notes.olympus.moe".extraConfig = ''
          reverse_proxy 127.0.0.1:3005

          import bunny
        '';
        virtualHosts."sso.olympus.moe".extraConfig = ''
          reverse_proxy 127.0.0.1:1411

          import bunny
        '';
        virtualHosts."netbird.olympus.moe".extraConfig = ''
          handle /api/* {
            reverse_proxy 127.0.0.1:8011
          }
          handle /management.ManagementService/* {
            reverse_proxy h2c://127.0.0.1:8011
          }
          handle /signalexchange.SignalExchange/* {
            reverse_proxy h2c://127.0.0.1:8012
          }
          handle {
            root * ${config.services.netbird.server.dashboard.finalDrv}
            try_files {path} {path}.html {path}/ /index.html
            file_server
          }
        '';
      };
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    };
}
