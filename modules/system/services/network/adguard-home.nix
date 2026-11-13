{ inputs, ... }:
{
  flake.nixosModules.adguard-home =
    {
      config,
      pkgs,
      lib,
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

      adapter = {
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
}
