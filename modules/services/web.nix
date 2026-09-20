{ inputs, self, ... }: {

  flake.nixosModules.web = { inputs, ... }: {
    imports = [
      inputs.self.nixosModules.adguardhome
      inputs.self.nixosModules.avahi
      inputs.self.nixosModules.atticd
      inputs.self.nixosModules.ntfy
      inputs.self.nixosModules.mollysocket
      inputs.self.nixosModules.forgejo-runner
      inputs.self.nixosModules.vaultwarden
    ];
  };

  flake.nixosModules.reverseProxy.imports = [ inputs.self.nixosModules.caddy ];

  flake.nixosModules.wireguardHost =
    { inputs, config, lib, ... }:
    let
      IPv4Address = {
        "nyx-nixos" = "192.168.10.253/32";
        "hermera-nixos" = "192.168.10.252/32";
        "aether-nixos" = "192.168.10.254/32";
      };
      IPv6Address = {
        "nyx-nixos" = "fd31:bf08:57cb::253/128";
        "hermera-nixos" = "fd31:bf08:57cb::252/128";
        "aether-nixos" = "fd31:bf08:57cb::254/128";
      };
      adapter = {
        "aether-nixos" = "ens3";
        "nyx-nixos" = "enp34s0";
      };
      publicKey = inputs.self.wireguardPublicKeys;
    in
    {
      sops.secrets."wireguard/${config.networking.hostName}/privateKey" = {
        mode = "640";
        owner = "systemd-network";
        group = "systemd-network";
      };

      networking.nat = {
        enable = true;
        enableIPv6 = true;
        externalInterface = adapter.${config.networking.hostName};
        internalInterfaces = [ "wg0" ];
        forwardPorts = lib.optionals (config.networking.hostName == "aether-nixos") [
          {
            sourcePort = 853;
            destination = "192.168.10.253:853";
          }
          {
            sourcePort = 853;
            proto = "udp";
            destination = "192.168.10.253:853";
          }
        ];
      };

      networking = {
        useNetworkd = true;
        firewall.allowedUDPPorts = [ 4500 ];
      };

      systemd.network = {
        enable = true;
        networks."50-wg0" = {
          matchConfig.Name = "wg0";

          address = [
            IPv4Address.${config.networking.hostName}
            IPv6Address.${config.networking.hostName}
          ];

          networkConfig = {
            IPv4Forwarding = true;
            IPv6Forwarding = true;
          };
        };

        netdevs."50-wg0" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "wg0";
          };

          wireguardConfig = {
            ListenPort = 4500;
            PrivateKeyFile = config.sops.secrets."wireguard/${config.networking.hostName}/privateKey".path;
            RouteTable = "main";
            FirewallMark = 42;
          };

          wireguardPeers = [
            /*
              {
                # athena-nixos
                PublicKey = "";
                AllowedIPs = [
                  "fd31:bf08:57cb::1/128"
                  "192.168.10.1/32"
                ];
              }
            */
            {
              # circe-nixos
              PublicKey = publicKey."circe-nixos";
              AllowedIPs = [
                "fd31:bf08:57cb::2/128"
                "192.168.10.2/32"
              ];
            }
            {
              PublicKey = publicKey."hermes";
              AllowedIPs = [
                "fd31:bf08:57cb::30/128"
                "192.168.10.30/32"
              ];
            }
            {
              # dionysus-nixos
              PublicKey = publicKey."dionysus-nixos";
              AllowedIPs = [
                "fd31:bf08:57cb::3/128"
                "192.168.10.3/32"
              ];
            }
            {
              #ariadne-nixos
              PublicKey = publicKey."ariadne-nixos";
              AllowedIPs = [
                "fd31:bf08:57cb::4/128"
                "192.168.10.4/32"
              ];
            }
          ]
          ++ lib.optionals (config.networking.hostName != "nyx-nixos") [
            {
              # nyx-nixos
              PublicKey = publicKey."nyx-nixos";
              AllowedIPs = [
                "fd31:bf08:57cb::253/128"
                "192.168.10.253/32"
              ];
            }
          ]
          ++ lib.optionals (config.networking.hostName != "aether-nixos") [
            {
              # aether-nixos
              PublicKey = publicKey."aether-nixos";
              AllowedIPs = [
                "fd31:bf08:57cb::254/128"
                "192.168.10.254/32"
              ];
              Endpoint = "vpn1.olympus.moe:4500";
              PersistentKeepalive = 25;
            }
          ];
        };
      };
    };

  flake.nixosModules.vaultwarden =
    { config, pkgs, ... }:
    let
      enabled = {
        "nyx-nixos" = true;
      };
    in
    {
      services.vaultwarden = {
        enable = enabled.${config.networking.hostName} or false;
        package = pkgs.vaultwarden-postgresql;
        dbBackend = "postgresql";

        configurePostgres = true;
        domain = "vault.olympus.moe";

        backupDir = null;
        environmentFile = "${config.sops.secrets."vaultwarden/env".path}";

        config = {
          SIGNUPS_ALLOWED = false;

          ROCKET_ADDRESS = "192.168.10.253";
          ROCKET_PORT = 8222;
          ROCKET_LOG = "critical";

          SMTP_HOST = "mail.olympus.moe";
          SMTP_SECURITY = "force_tls";
          SMTP_FROM = "admin@bitwarden.olympus.moe";
          SMTP_FROM_NAME = "Olympus.moe Bitwarden Server";
        };
      };
    };

  flake.nixosModules.forgejo-runner =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      virtualisation.docker = {
        enable = true;
        autoPrune.enable = true;
      };
      virtualisation.oci-containers.backend = "docker";
      virtualisation.docker.daemon.settings = {
        dns = [
          "1.1.1.1"
          "8.8.8.8"
        ];
      };

      # Containers
      virtualisation.oci-containers.containers."prometheus-runner" = {
        image = "docker.io/gitea/act_runner:nightly";
        environmentFiles = [
          "${config.sops.secrets."forgejo-runner/environment".path}"
        ];
        volumes = [
          "/home/server/olympus-nixos/modules/nyx/services/forgejo-runner/config:/config:rw"
          "/home/server/olympus-nixos/modules/nyx/services/forgejo-runner/data:/data:rw"
          "/var/run/docker.sock:/var/run/docker.sock:rw"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=runner"
          "--network=prometheus_default"
          "--dns=1.1.1.1"
          "--dns=8.8.8.8"
          "--memory=6144m"
          "--cpuset-cpus=0,1,2,3,4"
        ];
      };
      systemd.services."docker-prometheus-runner" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "no";
        };
        after = [
          "docker-network-prometheus_default.service"
        ];
        requires = [
          "docker-network-prometheus_default.service"
        ];
        partOf = [
          "docker-compose-prometheus-root.target"
        ];
        wantedBy = [
          "docker-compose-prometheus-root.target"
        ];
      };

      # Networks
      systemd.services."docker-network-prometheus_default" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "docker network rm -f prometheus_default";
        };
        script = ''
          docker network inspect prometheus_default || docker network create prometheus_default
        '';
        partOf = [ "docker-compose-prometheus-root.target" ];
        wantedBy = [ "docker-compose-prometheus-root.target" ];
      };

      # Root service
      # When started, this will automatically create all resources and start
      # the containers. When stopped, this will teardown all resources.
      systemd.targets."docker-compose-prometheus-root" = {
        unitConfig = {
          Description = "Root target generated by compose2nix.";
        };
        wantedBy = [ "multi-user.target" ];
      };
    };

  flake.nixosModules.mollysocket = { config, ... }: {
    services.mollysocket = {
      enable = true;
      settings = {
        host = "0.0.0.0";
        port = 8020;
        allowed_endpoints = [ "https://ntfy.olympus.moe" ];
        allowed_uuids = [ "a6be8ba5-eb84-42b9-a1f4-c22509904f61" ];
        vapid_key_file = "${config.sops.secrets."mollysocket/vapid_privkey".path}";
      };
    };

    systemd.services.mollysocket.serviceConfig = {
      User = "mollysocket";
    };

    users.users.mollysocket = {
      isSystemUser = true;
      group = "mollysocket";
    };

    users.groups.mollysocket = { };
  };

  flake.nixosModules.ntfy = { ... }: {
    services.ntfy-sh = {
      enable = true;
      settings = {
        base-url = "https://ntfy.olympus.moe";
        listen-http = ":1147";
      };
    };
  };

  flake.nixosModules.atticd =
    {
      inputs,
      pkgs,
      pkgs-unstable,
      config,
      lib,
      ...
    }:
    {
      imports = [
        inputs.attic.nixosModules.atticd
      ];

      environment.systemPackages =
        (with pkgs; [

        ])
        ++ (with pkgs-unstable; [
          attic-server
        ]);

      nix.settings.substituters = [ "http://localhost:7989/main" ];

      services.atticd = {
        enable = true;
        environmentFile = "${config.sops.secrets."attic/server-token".path}";
        package = pkgs-unstable.attic-server;

        settings = {
          listen = "[::]:7989";
          api-endpoint = "https://cache.puppygirls.net/";

          database.url = "postgresql:///attic?host=/run/postgresql&user=atticd";

          storage = {
            type = "local";
            path = "/media/hdd1/cache/";
          };

          garbage-collection = {
            interval = "48h";
          };

          jwt = { };

          chunking = {
            nar-size-threshold = 64 * 1024; # 64 KiB
            min-size = 16 * 1024; # 16 KiB
            avg-size = 64 * 1024; # 64 KiB
            max-size = 256 * 1024; # 256 KiB
          };
        };
      };

      services.postgresql.enable = true;

      systemd.services.postgresql.after = [ "media-hdd1.mount" ];
      systemd.services.postgresql.requires = [ "media-hdd1.mount" ];
      systemd.services.postgresql.serviceConfig.ReadWritePaths = [ "/media/hdd1/cache/attic-db" ];

      systemd.services.attic-db-setup = {
        description = "Bootstrap attic PostgreSQL database and tablespace";
        after = [ "postgresql.service" ];
        wantedBy = [ "atticd.service" ];
        before = [ "atticd.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "postgres";
          ExecStartPre = "+${pkgs.coreutils}/bin/install -d -m 0700 -o postgres -g postgres /media/hdd1/cache/attic-db";
        };
        path = [ config.services.postgresql.package ];
        script = ''
          psql -c "ALTER DATABASE template1 REFRESH COLLATION VERSION" || true
          psql -c "ALTER DATABASE postgres REFRESH COLLATION VERSION" || true

          psql -tc "SELECT 1 FROM pg_roles WHERE rolname = 'atticd'" \
            | grep -q 1 || psql -c "CREATE USER atticd"

          psql -tc "SELECT 1 FROM pg_tablespace WHERE spcname = 'attic'" \
            | grep -q 1 || psql -c "CREATE TABLESPACE attic LOCATION '/media/hdd1/cache/attic-db'"

          psql -tc "SELECT 1 FROM pg_database WHERE datname = 'attic'" \
            | grep -q 1 || psql -c "CREATE DATABASE attic TABLESPACE attic OWNER atticd"
        '';
      };

      systemd.services.atticd = {
        after = [ "attic-db-setup.service" ];
        requires = [ "attic-db-setup.service" ];
        serviceConfig = {
          ReadWritePaths = [ "/media/hdd1/cache" ];
          ProtectHome = lib.mkForce false;
          ProtectSystem = lib.mkForce "full";
        };
      };
    };

  flake.nixosModules.caddy =
    { config, pkgs, ... }:
    let
      puppygirls = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.puppygirls;
    in
    {
      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = [ "github.com/caddy-dns/bunny@v1.2.0" ];
          hash = "sha256-hj3+s8DWBH8hcbR000wQ89NnrElkJtiL+20q0tOSX+4=";
        };
        environmentFile = "${config.sops.secrets."caddy/environment".path}";
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
        virtualHosts."cache.puppygirls.net".extraConfig = ''
          reverse_proxy 192.168.10.253:7989 {
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
        virtualHosts."dns.puppygirls.net".extraConfig = ''
          reverse_proxy /dns-query* 192.168.10.253:854 {
            header_up X-Real-IP {remote_host}
            transport http {
              tls_insecure_skip_verify
            }
          }

          tls {
            dns bunny {$BUNNY_API}
          }
        '';
        virtualHosts."stream.puppygirls.net".extraConfig = ''
          reverse_proxy 192.168.10.253:8096 {
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

          reverse_proxy 192.168.10.253:5055 {
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

          reverse_proxy 192.168.10.253:5056 {
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

          reverse_proxy 192.168.10.253:5057 {
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

          reverse_proxy 192.168.10.253:5058 {
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

          reverse_proxy 192.168.10.253:5059 {
            header_up X-Real-IP {remote_host}
            transport http {
              versions 1.1
            }
          }
        '';

        virtualHosts."music.puppygirls.net".extraConfig = ''
          reverse_proxy 192.168.10.253:4533

          tls {
            dns bunny {$BUNNY_API}
          }
        '';
        virtualHosts."audio.puppygirls.net".extraConfig = ''
          reverse_proxy 192.168.10.253:8000

          tls {
            dns bunny {$BUNNY_API}
          }
        '';
        virtualHosts."https://ofsm.puppygirls.net".extraConfig = ''
          import mtls
          reverse_proxy 192.168.10.253:42702
        '';
        virtualHosts."https://crafty.puppygirls.net".extraConfig = ''
          import mtls
          reverse_proxy 192.168.10.253:8443 {
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
          reverse_proxy 192.168.10.253:8082

          tls {
            dns bunny {$BUNNY_API}
          }
        '';
        virtualHosts."https://rsshub.olympus.moe".extraConfig = ''
          reverse_proxy 192.168.10.253:1200

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

          reverse_proxy @mkcol_phonebackup 192.168.10.253:3210 {
            header_up X-Forwarded-For {remote_host}
            @exists status 405
            handle_response @exists {
              respond 201
            }
          }

          reverse_proxy 192.168.10.253:3210 {
            header_up X-Forwarded-For {remote_host}
          }

        '';
        virtualHosts."https://immich.olympus.moe".extraConfig = ''
          import mtls
          reverse_proxy 192.168.10.253:2283
        '';
        virtualHosts."https://home.olympus.moe".extraConfig = ''
          import mtls
          reverse_proxy 192.168.10.253:8123
        '';
        virtualHosts."https://budget.olympus.moe".extraConfig = ''
          encode gzip zstd
          reverse_proxy 192.168.10.253:5006
          import mtls
        '';
        virtualHosts."https://qbit.olympus.moe".extraConfig = ''
          encode gzip zstd
          reverse_proxy 192.168.10.253:8080

          import mtls
        '';
        virtualHosts."https://ntfy.olympus.moe".extraConfig = ''
          reverse_proxy 192.168.10.253:1147

          tls {
            dns bunny {$BUNNY_API}
          }
        '';
        virtualHosts."https://molly.olympus.moe".extraConfig = ''
          reverse_proxy 192.168.10.253:8020 {
            header_up Host {host}
          }

          tls {
            dns bunny {$BUNNY_API}
          }
        '';
        virtualHosts."https://vault.olympus.moe".extraConfig = ''
          import mtls
          reverse_proxy 192.168.10.253:8222
        '';
      };
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    };

  flake.nixosModules.avahi =
    {
      util,
      pkgs,
      lib,
      config,
      ...
    }:
    {
      services.avahi =
        let
          adapter = {
            "aether-nixos" = "ens3";
            "nyx-nixos" = "enp34s0";
          };
        in
        {
          enable = true;
          openFirewall = true;
          allowInterfaces = [
            adapter.${config.networking.hostName}
          ];
          publish = {
            enable = true;
            domain = true;
            userServices = true;
          };
          nssmdns4 = true;
        };

      systemd.sockets.avahi-daemon = {
        wantedBy = lib.mkForce [ ];
        requiredBy = lib.mkForce [ ];
      };
      systemd.services.avahi-daemon.requires = lib.mkForce [ ];
    };

  flake.nixosModules.adguardhome =
    { lib, config, ... }:
    let
      adapter = {
        "aether-nixos" = "ens3";
        "nyx-nixos" = "enp34s0";
      };
    in
    {
      services.adguardhome = {
        enable = true;
        host = "0.0.0.0";
        mutableSettings = false;
        port = 3003;
        allowDHCP = false;
        settings = {
          dns = {
            upstream_dns = [
              "9.9.9.9"
              "8.8.8.8"
              "8.8.4.4"
            ];
            bootstrap_dns = [
              "9.9.9.9"
            ];
            #aaaa_disabled = true;
          };
          tls = {
            enabled = true;
            server_name = "dns.puppygirls.net";
            serve_plain_dns = false;
            force_https = false;
            port_https = 854;
            port_dns_over_tls = 853;
            certificate_path = "${config.sops.secrets."adguardhome/domain_cert".path}";
            private_key_path = "${config.sops.secrets."adguardhome/domain_key".path}";
          };
          dhcp = {
            enabled = false;
            interface_name = adapter.${config.networking.hostName};
            dhcpv4 = {
              gateway_ip = "172.17.0.254";
              subnet_mask = "255.255.0.0";
              lease_duration = 0;
              range_start = "172.17.0.2";
              range_end = "172.17.0.243";
            };
          };
          filtering = {
            protection_enabled = true;
            filtering_enabled = true;

            parental_enabled = false;
            safe_search = {
              enabled = false;
            };
            # VPN member names, answered locally from wg addresses.
            # AdGuard reads rewrites from the `filtering` block, not `dns`.
            rewrites = lib.concatMap
              (host: [
                {
                  domain = "${host.name}.vpn.olympus.moe";
                  answer = host.v4;
                  enabled = true;
                }
                {
                  domain = "${host.name}.vpn.olympus.moe";
                  answer = host.v6;
                  enabled = true;
                }
                {
                  domain = host.name;
                  answer = host.v4;
                  enabled = true;
                }
                {
                  domain = host.name;
                  answer = host.v6;
                  enabled = true;
                }
              ])
              [
                { name = "athena-nixos"; v4 = "192.168.10.1"; v6 = "fd31:bf08:57cb::1"; }
                { name = "circe-nixos"; v4 = "192.168.10.2"; v6 = "fd31:bf08:57cb::2"; }
                { name = "dionysus-nixos"; v4 = "192.168.10.3"; v6 = "fd31:bf08:57cb::3"; }
                { name = "ariadne-nixos"; v4 = "192.168.10.4"; v6 = "fd31:bf08:57cb::4"; }
                { name = "nyx-nixos"; v4 = "192.168.10.253"; v6 = "fd31:bf08:57cb::253"; }
                { name = "hermera-nixos"; v4 = "192.168.10.252"; v6 = "fd31:bf08:57cb::252"; }
                { name = "aether-nixos"; v4 = "192.168.10.254"; v6 = "fd31:bf08:57cb::254"; }
              ];
          };

          trusted_proxies = [
            "127.0.0.1"
            "172.17.100.1"
          ];

          filters =
            map
              (url: {
                enabled = true;
                url = url;
              })
              [
                "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt"
                "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/refs/heads/master/SmartTV.txt"
                "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.txt"
                "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/popupads.txt"
              ];

          whitelist_filters =
            map
              (url: {
                enabled = true;
                url = url;
              })
              [
                "https://dawn.wine/foxtrottt/olympus-nixos/raw/branch/main/modules/nyx/services/networking/adguardhome/allowlist.txt"
              ];

          protection_enabled = false;
        };
      };

      systemd.services.adguardhome = {
        serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = "server";
        };
      };
    };
}
