{ inputs, self, ... }: {

  flake.nixosModules.web = { inputs, ... }: {
    imports = [
      inputs.self.nixosModules.dnsHost
      inputs.self.nixosModules.avahi
      inputs.self.nixosModules.atticd
      inputs.self.nixosModules.ntfy
      inputs.self.nixosModules.sso
    ];
  };

  flake.nixosModules.reverseProxy.imports = [ inputs.self.nixosModules.caddy ];

  flake.nixosModules.sso =
    {
      config,
      pkgs,
      ...
    }:
    {
      services.pocket-id = {
        enable = true;
        user = "pocket-id";
        group = "pocket-id";
        package = pkgs.pocket-id;
        dataDir = "/media/hdd1/services/pocket-id";

        settings = {
          APP_URL = "https://sso.olympus.moe";
          TRUST_PROXY = true;
        };

        credentials = {
          ENCRYPTION_KEY = config.sops.secrets."pocket-id/encryption".path;
          MAXMIND_LICENSE_KEY = config.sops.secrets."pocket-id/maxmind".path;
        };
      };

      users.users.pocket-id = {
        isSystemUser = true;
        group = "pocket-id";
      };

      users.groups.pocket-id = { };
    };

  # WireGuard hub duties moved to the NetBird overlay: aether keeps acting as the
  # public ingress (NAT forwardPorts) and Mullvad exit, but the raw mesh device
  # is gone; forwarded traffic rides nb-wt0 to nyx (pinned 192.168.10.253).
  flake.nixosModules.aetherIngress =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = lib.mkIf (config.networking.hostName == "aether-nixos") {
        networking.nat = {
          enable = true;
          enableIPv6 = true;
          externalInterface = "ens3";
          internalInterfaces = [ "nb-wt0" ];
          forwardPorts = [
            {
              sourcePort = 853;
              destination = "192.168.10.253:853";
            }
            {
              sourcePort = 853;
              proto = "udp";
              destination = "192.168.10.253:853";
            }
            {
              sourcePort = 25565;
              destination = "192.168.10.253:25665";
            }
            {
              sourcePort = 25665;
              destination = "192.168.10.253:25665";
            }
            {
              sourcePort = 25865;
              destination = "192.168.10.253:25865";
            }
          ];
        };

        networking.firewall = {
          allowedUDPPorts = [ 853 ];
          allowedTCPPorts = [
            853
            25565
            25665
            25865
          ];
        };

        # No .network file for nb-wt0: matching one makes networkd claim the
        # link and flush netbird's direct netlink address assignment. Forwarding
        # is covered by the global ip_forward sysctls (needed anyway for the
        # mullvad exit module); the iif policy rule lives in iproute2 setup.
        boot.kernel.sysctl = {
          "net.ipv4.ip_forward" = true;
          "net.ipv6.conf.all.forwarding" = true;
        };

        systemd.services.netbird-mullvad-rule = {
          description = "Policy rule: netbird overlay traffic routed via Mullvad tunnel";
          after = [
            "network.target"
            "netbird-wt0.service"
          ];
          wants = [ "netbird-wt0.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "nb-mullvad-rule" ''
              #!${pkgs.stdenv.shell}
              ip=${pkgs.iproute2}/bin/ip
              for attempt in 1 2 3 4 5 6 7 8 9 10; do
                "$ip" -4 rule add iif nb-wt0 table 51820 priority 100 2>/dev/null || true
                "$ip" -6 rule add iif nb-wt0 table 51820 priority 100 2>/dev/null || true
                if "$ip" -4 rule show | grep -q "iif nb-wt0"; then
                  echo "policy rules installed"
                  exit 0
                fi
                sleep 3
              done
              echo "failed to install nb-wt0 policy rules" >&2
              exit 1
            '';
            ExecStop = pkgs.writeShellScript "nb-mullvad-rule-stop" ''
              ${pkgs.iproute2}/bin/ip -4 rule del iif nb-wt0 table 51820 priority 100 2>/dev/null || true
              ${pkgs.iproute2}/bin/ip -6 rule del iif nb-wt0 table 51820 priority 100 2>/dev/null || true
            '';
          };
        };
      };
    };

  flake.nixosModules.routeVPNMullvad = { config, pkgs, ... }: {
    systemd.network = {
      netdevs."60-wg-mullvad1" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg-mullvad1";
        };
        wireguardConfig = {
          PrivateKeyFile = config.sops.secrets."wireguard/mullvad/privkey".path;
          FirewallMark = 51820;
          RouteTable = 51820;
        };
        wireguardPeers = [
          {
            PublicKey = "HjcUGVDXWdrRkaKNpc/8494RM5eICO6DPyrhCtTv9Ws=";
            AllowedIPs = [
              "0.0.0.0/0"
              "::/0"
            ];
            Endpoint = "143.244.47.78:3489";
          }
        ];
      };

      networks."60-wg-mullvad1" = {
        matchConfig.Name = "wg-mullvad1";
        address = [
          "10.72.161.131/32"
          "fc00:bbbb:bbbb:bb01::9:a182/128"
        ];
      };

    };

    networking.iproute2.rttablesExtraConfig = ''
      100 nb-wt0-mullvad
    '';

    networking.nat = {
      extraCommands = ''
        # netbird overlay -> mullvad exit masquerade
        iptables -w -t nat  -A nixos-nat-post -o wg-mullvad1 -i nb-wt0  -j MASQUERADE
        ip6tables -w -t nat -A nixos-nat-post -o wg-mullvad1 -i nb-wt0  -j MASQUERADE
      '';

      extraStopCommands = ''
        # netbird overlay
        iptables -w -t nat  -D nixos-nat-post -o wg-mullvad1 -i nb-wt0  -j MASQUERADE || true
        ip6tables -w -t nat -D nixos-nat-post -o wg-mullvad1 -i nb-wt0  -j MASQUERADE || true
      '';
    };

    sops.secrets."netbird/api/pat" = {
      sopsFile = ../../secrets/${config.networking.hostName}.yaml;
      mode = "640";
      owner = "root";
      group = "root";
    };

    systemd.services.netbird-mullvad-route = {
      description = "Provision Mullvad exit-node route in netbird management (idempotent)";
      after = [
        "network-online.target"
        "netbird-management.service"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeScript "netbird-mullvad-route.sh" ''
          #!${pkgs.bash}/bin/bash
          set -uo pipefail

          API=https://netbird.olympus.moe/api
          PAT=$(<${config.sops.secrets."netbird/api/pat".path})
          curl=${pkgs.curl}/bin/curl
          jq=${pkgs.jq}/bin/jq
          auth=(-H "Authorization: Token $PAT")

          req() {
            local m=$1 path=$2 body=''${3-} out code
            if [ -n "$body" ]; then
              out=$($curl -sS --show-error -w "\n%{http_code}" -X "$m" "''${auth[@]}" -H "Content-Type: application/json" -d "$body" "$API$path") \
                || { echo "request to $path failed: $out" >&2; exit 1; }
            else
              out=$($curl -sS --show-error -w "\n%{http_code}" "''${auth[@]}" "$API$path") \
                || { echo "request to $path failed" >&2; exit 1; }
            fi
            code="''${out##*$'\n'}"
            body="''${out%$'\n'*}"
            if [ "$code" -lt 200 ] || [ "$code" -ge 400 ]; then
              echo "API $m $path -> HTTP $code: $(printf '%s' "$body" | head -c 300)" >&2
              exit 1
            fi
            printf '%s' "$body"
          }

          until $curl -sf "''${auth[@]}" "$API/peers" >/dev/null 2>&1; do
            echo "management API unreachable, retrying"
            sleep 5
          done

          peer=$(req GET /peers | $jq -c '[.[] | select(.name=="aether-nixos")] | .[0] // empty')
          [ -n "$peer" ] || { echo "aether-nixos peer not found"; exit 1; }
          peer_id=$($jq -rn --argjson p "$peer" '$p.id')

          dist=$(req GET /groups | $jq -c '[.[] | select(.name=="mullvad-exit-users")] | .[0] // empty')
          if [ -z "$dist" ]; then
            dist=$(req POST /groups '{"name":"mullvad-exit-users"}')
          fi
          dist_id=$($jq -rn --argjson g "$dist" '$g.id')
          [ -n "$dist_id" ] || { echo "failed to ensure distribution group"; exit 1; }

          body=$($jq -nc --arg dist "$dist_id" --arg peer "$peer_id" '{
            description: "Mullvad exit node (aether)",
            network_id: "mullvad-exit",
            enabled: true,
            network: "0.0.0.0/0",
            metric: 9999,
            masquerade: true,
            keep_route: false,
            skip_auto_apply: true,
            groups: [$dist],
            peer: $peer
          }')

          existing=$(req GET /routes | $jq -c '[.[] | select(.network_id=="mullvad-exit")] | .[0] // empty')
          if [ -n "$existing" ]; then
            rid=$($jq -rn --argjson e "$existing" '$e.id')
            req PUT /routes/$rid "$body" >/dev/null
            echo "exit route updated"
          else
            req POST /routes "$body" >/dev/null
            echo "exit route created"
          fi
        '';
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
      virtualisation.podman = {
        enable = true;
        autoPrune.enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };
      virtualisation.oci-containers.backend = "podman";

      # Containers
      virtualisation.oci-containers.containers."prometheus-runner" = {
        image = "docker.io/gitea/act_runner:0.6.1";
        environmentFiles = [
          "${config.sops.secrets."forgejo-runner/environment".path}"
        ];
        volumes = [
          "/home/server/olympus-nixos/modules/nyx/services/forgejo-runner/config:/config:rw"
          "/home/server/olympus-nixos/modules/nyx/services/forgejo-runner/data:/data:rw"
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
      systemd.services."podman-prometheus-runner" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "no";
        };
        after = [
          "podman-network-prometheus_default.service"
        ];
        requires = [
          "podman-network-prometheus_default.service"
        ];
        partOf = [
          "podman-compose-prometheus-root.target"
        ];
        wantedBy = [
          "podman-compose-prometheus-root.target"
        ];
      };

      # Networks
      systemd.services."podman-network-prometheus_default" = {
        path = [ pkgs.podman ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "podman network rm -f prometheus_default";
        };
        script = ''
          podman network inspect prometheus_default || podman network create prometheus_default
        '';
        partOf = [ "podman-compose-prometheus-root.target" ];
        wantedBy = [ "podman-compose-prometheus-root.target" ];
      };

      # Root service
      # When started, this will automatically create all resources and start
      # the containers. When stopped, this will teardown all resources.
      systemd.targets."podman-compose-prometheus-root" = {
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
        auth-default-access = "deny-all";
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

  flake.nixosModules.networkPassthrough =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = [
            "github.com/mholt/caddy-l4@v0.1.2"
          ];
          hash = "sha256-FwGmHobFqBkEI7LN/YaPsL0t+dJn8uZMhCp9asDEsYw=";
        };
        environmentFile = "${config.sops.secrets."caddy/environment".path}";
        globalConfig = ''
          layer4 {
            :443 {
              route {
                proxy {
                  upstream 192.168.200.2:443
                }
              }
            }

            :80 {
              route {
                proxy {
                  upstream 192.168.200.2:80
                }
              }
            }

            :33093 {
              route {
                proxy {
                  upstream 192.168.200.2:33080
                }
              }
            }
          }
        '';
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
        33093
      ];
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

  flake.nixosModules.dnsHost =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      meshIp = "192.168.10.253";
      # Served from aether's public ingress, not from nyx's 443 vhosts, so the
      # mesh instance must hand out the public records instead of the wildcard.
      publicNames = [
        "/netbird.olympus.moe/"
        "/dns.puppygirls.net/"
        "/ssh.olympus.moe/"
        "/vpn.olympus.moe/"
        "/www.olympus.moe/"
      ];
      meshConfig = pkgs.writeText "dnsmasq-mesh.conf" ''
        port=53
        listen-address=${meshIp}
        bind-dynamic
        no-resolv
        local-service
        server=127.0.0.1#53
        ${lib.concatMapStrings (name: "server=${name}127.0.0.1#53\n") publicNames}
        address=/olympus.moe/${meshIp}
        address=/puppygirls.net/${meshIp}
        local=/olympus.moe/
        local=/puppygirls.net/
      '';
    in
    {
      imports = [ inputs.self.nixosModules.adguardhome ];

      # LAN resolver; *.olympus.moe answers point at nyx's LAN address.
      services.dnsmasq = {
        enable = true;
        settings = {
          port = 53;
          listen-address = [ "172.17.100.1" ];
          # lets dnsmasq bind early / survive netbird bringing the overlay address up later
          bind-dynamic = true;
          no-resolv = true;
          local-service = true;
          server = [
            "127.0.0.1#53"
            "/ssh.olympus.moe/127.0.0.1#53"
            "/vpn.olympus.moe/127.0.0.1#53"
            "/www.olympus.moe/127.0.0.1#53"
          ];
          address = [
            "/olympus.moe/172.17.100.1"
            "/puppygirls.net/172.17.100.1"
          ];
          local = [
            "/olympus.moe/"
            "/puppygirls.net/"
          ];
        };
      };

      # NetBird peers are given this instance as their nameserver, so answers
      # have to be overlay-reachable. 172.17.100.1 is not: it is LAN-only and
      # firewalled off from non-172.17/16 sources, which blackholes netbird's
      # own control plane (management/signal/relay/TURN all live on
      # netbird.olympus.moe) as soon as the peer re-resolves it.
      systemd.services.dnsmasq-mesh = {
        description = "DNS resolver for netbird overlay peers (split-horizon answers)";
        after = [
          "network.target"
          "adguardhome.service"
        ];
        wants = [ "adguardhome.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.dnsmasq}/bin/dnsmasq -k --user=dnsmasq -C ${meshConfig}";
          Restart = "always";
          RestartSec = "2s";
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = true;
        };
      };

      # Router forwards 53 here; the LAN reaches this loop.
      networking.firewall.extraCommands = lib.mkAfter ''
        for proto in tcp udp; do
          iptables -C INPUT -d 172.17.100.1 -p $proto --dport 53 ! -s 172.17.0.0/16 -j DROP 2>/dev/null \
            || iptables -I INPUT 1 -d 172.17.100.1 -p $proto --dport 53 ! -s 172.17.0.0/16 -j DROP
        done
      '';
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
            bind_hosts = [
              "127.0.0.1"
            ];
            # dnsmasq fronts this resolver, so all LAN clients share the
            # 127.0.0.1 rate-limit bucket; ratelimit_whitelist is inert in
            # 0.107.x, so keep a wide per-client budget instead.
            ratelimit = 200;
            ratelimit_whitelist = [ "127.0.0.1" ];
            # resolv.conf advertises ::1, where nothing listens.
            local_ptr_upstreams = [
              "9.9.9.9"
              "8.8.8.8"
              "8.8.4.4"
            ];
          };
          tls = {
            enabled = true;
            server_name = "dns.puppygirls.net";
            serve_plain_dns = false;
            force_https = true;
            port_https = 854;
            port_dns_over_tls = 853;
            certificate_path = "/var/lib/acme/dns.puppygirls.net/cert.pem";
            private_key_path = "/var/lib/acme/dns.puppygirls.net/key.pem";
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
            # VPN member names, answered locally from netbird addresses.
            # AdGuard reads rewrites from the `filtering` block, not `dns`.

            rewrites =
              lib.concatMap
                (host: [
                  {
                    domain = "${host.name}.vpn.olympus.moe";
                    answer = host.v4;
                    enabled = true;
                  }
                  {
                    domain = host.name;
                    answer = host.v4;
                    enabled = true;
                  }
                ])
                [
                  {
                    name = "athena-nixos";
                    v4 = "192.168.10.1";
                  }
                  {
                    name = "circe-nixos";
                    v4 = "192.168.10.2";
                  }
                  {
                    name = "dionysus-nixos";
                    v4 = "192.168.10.3";
                  }
                  {
                    name = "ariadne-nixos";
                    v4 = "192.168.10.4";
                  }
                  {
                    name = "hermes-graphene";
                    v4 = "192.168.10.30";
                  }
                  {
                    name = "nyx-nixos";
                    v4 = "192.168.10.253";
                  }
                  {
                    name = "aether-nixos";
                    v4 = "192.168.10.252";
                  }
                ];
          };

          trusted_proxies = [
            "127.0.0.1"
            "172.17.100.1"
          ];

          filters =
            lib.imap1
              (
                id: filter:
                filter
                // {
                  inherit id;
                  enabled = true;
                }
              )
              [
                {
                  name = "HaGeZi Multi PRO";
                  url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt";
                }
                {
                  name = "Perflyst SmartTV";
                  url = "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/refs/heads/master/SmartTV.txt";
                }
                {
                  name = "HaGeZi TIF";
                  url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.txt";
                }
                {
                  name = "HaGeZi PopupAds";
                  url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/popupads.txt";
                }
              ];

          whitelist_filters = [
            {
              id = 101;
              enabled = true;
              name = "Olympus allowlist";
              url = "https://dawn.wine/foxtrottt/olympus-nixos/raw/branch/main/assets/allowlist.txt";
            }
          ];

        };
      };

      systemd.services.adguardhome = {
        serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = "adguardhome";
        };
        # netbird's overlay IP may lag service start; allow unbounded retries
        unitConfig.StartLimitIntervalSec = lib.mkForce 0;
      };

      # Manage cert to allow DNS encryption :3
      security.acme = {
        acceptTerms = true;
        defaults.email = "code@olympus.moe";
        certs."dns.puppygirls.net" = {
          dnsProvider = "bunny";
          group = "adguardhome";
          environmentFile = config.sops.secrets."adguardhome/environment".path;
          reloadServices = [ "adguardhome" ];
        };
      };

      users.users.adguardhome = {
        isSystemUser = true;
        group = "adguardhome";
      };

      users.groups.adguardhome = { };
    };

  flake.nixosModules.atuinServer = { config, pkgs, ... }: {
    services.atuin = {
      enable = true;
      package = pkgs.atuin;
      host = "::";
      port = 1823;
      environmentFile = config.sops.secrets."atuin/env".path;
      database = {
        createLocally = true;
      };
    };

    networking.firewall.allowedTCPPorts = [ config.services.atuin.port ];
  };

  flake.nixosModules.atuinAIServer =
    { config, pkgs, ... }:
    let
      configToml = pkgs.writeText "atuin-ai-config.toml" ''
        port = 1824
        endpoint = "https://api.fireworks.ai/inference/v1"
        api_key = { env = "FIREWORKS_API_KEY" }

        default_model = "glm-5p3-flash"

        [request.body]
        stream_options = { include_usage = true }

        [request.headers]
        Authorization = "Bearer {{api_key}}"
        user-agent = "atuin-ai-server/1.0"
        x-opencode-session = "9c1d4b7e-2a63-4f18-9e5b-7d0a2c6f8b34"

        [[models]]
        alias = "glm-5p3-flash"
        name = "GLM 5.3 Flash"
        description = "Fireworks API - GLM Flash Latest"
        model = "accounts/fireworks/routers/glm-5p3-flash"
      '';
    in
    {
      virtualisation.oci-containers.containers."atuin-ai-server" = {
        image = "ghcr.io/atuinsh/atuin-ai-server:latest";
        environmentFiles = [ config.sops.secrets."atuin/ai-env".path ];
        volumes = [ "${configToml}:/etc/atuin-ai/config.toml:ro" ];
        log-driver = "journald";
        extraOptions = [
          "--network=host"
        ];
      };

      networking.firewall.allowedTCPPorts = [ 1824 ];
    };

  flake.nixosModules.homepage = { config, pkgs, ... }: {
    services.homepage-dashboard = {
      enable = true;
      listenPort = 8085;
      allowedHosts = "dash.olympus.moe,192.168.10.253:8085,localhost:8085,127.0.0.1:8085";
      environmentFiles = [
        "${config.sops.secrets."homepage/secrets".path}"
      ];

      settings = {
        title = "Olympus Network";
        description = "Dashboard for 'Olympus' HomeLab";
        theme = "dark";

        layout = {
          "Media" = {
            style = "row";
            columns = 4;
          };
        };

        headerStyle = "underlined";
      };

      widgets = [
        {
          resources = {
            cpu = true;
            disk = "/media/hdd1";
            memory = true;
          };
        }
        {
          search = {
            provider = "duckduckgo";
            target = "_blank";
          };
        }
      ];

      services = [
        {
          "Tools" = [
            {
              "ActualBudget" = {
                description = "Self-Hosted budgeting service. | Requires mTLS";
                icon = "actual-budget.png";
                href = "https://budget.olympus.moe";
                ping = "http://localhost:5006";
              };
            }
          ];
        }
        {
          "Media" = [
            {
              "Jellyfin" = {
                description = "Self-Hosted Streaming Service";
                icon = "jellyfin.png";
                href = "https://stream.puppygirls.net";
                siteMonitor = "http://localhost:8096";
              };
            }
            {
              "Seerr" = {
                description = "Movie and TV-Show request service.";
                icon = "jellyfin.png";
                href = "https://seerr.puppygirls.net";
                siteMonitor = "http://localhost:5055";
              };
            }
            {
              "Immich" = {
                description = "Self-Hosted Image Service | Requires mTLS";
                icon = "immich.png";
                href = "https://immich.olympus.moe";
                ping = "http://localhost:2283";
              };
            }
            {
              "Navidrome" = {
                description = "Self-Hosted Music Streaming Service";
                icon = "navidrome.png";
                href = "https://music.puppygirls.net";
                siteMonitor = "http://localhost:4533";
              };
            }
            {
              "Audio Bookshelf" = {
                description = "Self-Hosted Audiobook Service";
                icon = "audiobookshelf.png";
                href = "https://audio.puppygirls.net";
                siteMonitor = "http://localhost:8000";
              };
            }
            {
              "FreshRSS" = {
                description = "Self-Hosted RSS Feed. | Requires mTLS";
                icon = "freshrss.png";
                href = "https://rss.olympus.moe";
                ping = "http://localhost:8082";
              };
            }
          ];
        }
        {
          "Services" = [
            {
              "DNS" = {
                description = "Self Hosted AdGuard DNS";
                icon = "adguard-home.png";
                ping = "http://localhost:854";
                widget = {
                  type = "adguard";
                  url = "http://localhost:3003";
                  username = "foxtrot";
                  password = "$ADGUARD_PASS";
                };
              };
            }
            {
              "Nix Cache" = {
                description = "Self Hosted NixOS binary cache";
                icon = "nixos.png";
                siteMonitor = "http://localhost:7989";
              };
            }
            {
              "Ntfy" = {
                description = "Ntfy Notification Service";
                icon = "ntfy.png";
                ping = "http://localhost:1147";
              };
            }
            {
              "Mollysocket" = {
                description = "Mollysocket Notification Daemon";
                icon = "https://avatars.githubusercontent.com/u/58849401?s=60&v=4";
                ping = "http://localhost:8020";
              };
            }
            {
              "RSSHub" = {
                description = "RSS Hub Service";
                icon = "rsshub.png";
                siteMonitor = "http://localhost:1200";
              };
            }
            {
              "Llama-CPP" = {
                description = "llama.cpp Instance";
                icon = "https://avatars.githubusercontent.com/u/134263123?s=60&v=4";
                ping = "http://localhost:5387";
              };
            }
          ];
        }
        {
          "Game Servers" = [
            {
              "Factorio" = {
                description = "Factorio";
                icon = "https://cdn2.steamgriddb.com/icon/6ca4e9af5ea662a095c3243dc591bf54/32/256x256.png";
                href = "https://factory.puppygirls.net";
                ping = "http://localhost:42702";
              };
            }
            {
              "Vanilla | Minecraft" = {
                description = "forever.puppygirls.net";
                icon = "minecraft.png";
                widget = {
                  type = "minecraft";
                  url = "udp://localhost:25865";
                };
              };
            }
            {
              "NTNH | Minecraft" = {
                description = "statech.puppygirls.net";
                icon = "https://avatars.githubusercontent.com/u/209024689?s=200&v=4";
                widget = {
                  type = "minecraft";
                  url = "udp://localhost:25665";
                };
              };
            }
          ];
        }
        {
          "Admin Tools" = [
            {
              "qBittorrent" = {
                description = "qBittorrent Instance | Requires mTLS";
                icon = "qbittorrent.png";
                href = "https://qbit.olympus.moe";
                ping = "http://localhost:8080";
              };
            }
            {
              "Home Assistant" = {
                description = "Home Assistant | Requires mTLS";
                icon = "home-assistant.png";
                href = "https://home.olympus.moe";
                ping = "http://localhost:8123";
              };
            }
            {
              "Copyparty" = {
                description = "Copyparty Instance | Requires mTLS";
                icon = "copyparty.png";
                href = "https://copy.olympus.moe";
                ping = "http://localhost:3120";
              };
            }
            {
              "Radarr" = {
                description = "Movie Fetching Service";
                icon = "radarr.png";
                href = "https://radarr.puppygirls.net";
                siteMonitor = "http://localhost:5056";
              };
            }
            {
              "Sonarr" = {
                description = "Show Fetching Service";
                icon = "sonarr.png";
                href = "https://sonarr.puppygirls.net";
                siteMonitor = "http://localhost:5057";
              };
            }
            {
              "Prowlarr" = {
                description = "Index Provider Service";
                icon = "prowlarr.png";
                href = "https://prowlarr.puppygirls.net";
                siteMonitor = "http://localhost:5058";
              };
            }

          ];
        }
      ];
    };
  };

  flake.nixosModules.futo-notes-server =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      systemd.services.futo-notes-server = {
        description = "FUTO Notes live-sync server";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = lib.getExe inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.futo-notes-server;
          User = "futo-notes";
          Group = "futo-notes";
          EnvironmentFile = config.sops.secrets."futo-notes/environment".path;
          WorkingDirectory = "/media/hdd1/services/futo-notes";
          Restart = "on-failure";
        };
      };

      users.users.futo-notes = {
        description = "FUTO Notes Server user";
        isSystemUser = true;
        group = "futo-notes";
        extraGroups = [ "users" ];
        hashedPasswordFile = config.sops.secrets."users/server".path;
      };

      users.groups.futo-notes = { };
    };
}
