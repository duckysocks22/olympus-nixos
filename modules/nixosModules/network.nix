{ inputs, self, ... }: {
  flake.nixosModules.defaultNetwork =
    {
      config,
      pkgs,
      pkgs-unstable,
      lib,
      ...
    }:
    let
      staticIp = {
        "athena-nixos" = "172.17.25.1/16";
        "circe-nixos" = "172.17.25.2/16";
        "ariadne-nixos" = "172.17.25.3/16";
        "dionysus-nixos" = "172.17.25.4/16";
      };
      autoconnect = {
        "athena-nixos" = "false";
        "circe-nixos" = "true";
        "ariadne-nixos" = "true";
        "dionysus-nixos" = "true";
      };
      ethDevice = {
        "athena-nixos" = "";
        "circe-nixos" = "null";
        "dionysus-nixos" = "null";
        "ariadne-nixos" = "enp5s0";
      };
      wifiRecover = pkgs.writeShellScript "wifi-recover" ''
        mode="$1"
        nm=${config.networking.networkmanager.package}/bin/nmcli
        if [ "$mode" = resume ]; then
          "$nm" networking off || true
          systemctl try-restart iwd.service || true
          for i in $(seq 1 10); do
            [ "$(systemctl is-active iwd.service)" = active ] && break
            sleep 1
          done
        fi
        "$nm" networking on || true
        forced=0
        for i in $(seq 1 30); do
          if "$nm" -t -f DEVICE,TYPE,STATE device status 2>/dev/null | \
            awk -F: '$2 == "wifi" && $3 ~ /^connected/ { found = 1 } END { exit !found }'; then
            exit 0
          fi
          if [ "$forced" = 0 ] && [ "$i" -ge 10 ]; then
            forced=1
            dev=$("$nm" -t -f DEVICE,TYPE device status 2>/dev/null | awk -F: '$2 == "wifi" { print $1; exit }')
            if [ -n "$dev" ]; then
              "$nm" device connect "$dev" || true
            fi
          fi
          sleep 2
        done
        echo "wifi-recover[$mode]: wifi did not reconnect within timeout" >&2
        exit 1
      '';
      dnsPin = pkgs.writeShellScript "dns-pin" ''
        case "$ACTION" in
          up|dhcp4-change|dhcp6-change|reapply) ;;
          *) exit 0 ;;
        esac
        if [ -z "$CONNECTION_ID" ] || [ -z "$DEVICE_INTERFACE" ]; then
          exit 0
        fi
        ${config.networking.networkmanager.package}/bin/nmcli con modify "$CONNECTION_ID" ipv4.ignore-auto-dns true ipv6.ignore-auto-dns true ipv4.dns 127.0.0.1 >/dev/null 2>&1 || true
        ${pkgs.systemd}/bin/resolvectl dns "$DEVICE_INTERFACE" 127.0.0.1 >/dev/null 2>&1 || true
      '';
    in
    {
      imports = [
        inputs.self.nixosModules.mullvad
        inputs.self.nixosModules.dnscrypt-proxy
        inputs.self.nixosModules.wireguardPeer
      ];

      networking = {
        networkmanager = {
          enable = true;
          logLevel = "INFO";
          wifi = {
            backend = "iwd";
            powersave = false;
            scanRandMacAddress = false;
          };
          dispatcherScripts = [
            {
              source = dnsPin;
              type = "basic";
            }
          ];
          ensureProfiles = {
            environmentFiles = [ config.sops.secrets."bazinga/pass".path ];
            profiles.bazinga = {
              connection = {
                id = "bazinga";
                type = "wifi";
                autoconnect = autoconnect.${config.networking.hostName};
                autoconnect-priority = 100;
              };
              wifi.ssid = "bazinga";
              wifi-security = {
                key-mgmt = "wpa-psk";
                psk = "$BAZINGA_PSK";
              };
              ipv4 = {
                method = "manual";
                address1 = staticIp.${config.networking.hostName};
                gateway = "172.17.0.254";
                dns = "127.0.0.1";
                ignore-auto-dns = true;
              };
              ipv6 = {
                addr-gen-mode = "stable-privacy";
                method = "auto";
                ignore-auto-dns = true;
              };
            };
          };
          unmanaged = [ ethDevice.${config.networking.hostName} ];
        };
        firewall = {
          allowedTCPPorts = [ 4646 8384 ];
          allowedUDPPorts = [ 4646 8384 ];
        };
      };

      systemd.services.NetworkManager = {
        after = [ "iwd.service" ];
        wants = [ "iwd.service" ];
      };
      systemd.services.NetworkManager-ensure-profiles = {
        after = [ "sops-install-secrets.service" ];
        wants = [ "sops-install-secrets.service" ];
      };

      systemd.services.wifi-recover-boot = lib.mkIf (autoconnect.${config.networking.hostName} == "true") {
        description = "Ensure wifi autoconnect completes after declarative profiles are ensured";
        wantedBy = [ "multi-user.target" ];
        after = [
          "NetworkManager.service"
          "NetworkManager-ensure-profiles.service"
          "iwd.service"
        ];
        wants = [ "NetworkManager-ensure-profiles.service" ];
        path = [ pkgs.coreutils pkgs.gawk ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${wifiRecover} boot";
          TimeoutStartSec = "3min";
        };
      };
      systemd.services.wifi-recover-resume = lib.mkIf (autoconnect.${config.networking.hostName} == "true") {
        description = "Re-establish wifi after suspend/resume (iwd/NM state desync)";
        wantedBy = [
          "suspend.target"
          "hibernate.target"
          "hybrid-sleep.target"
          "suspend-then-hibernate.target"
        ];
        after = [
          "suspend.target"
          "hibernate.target"
          "hybrid-sleep.target"
          "suspend-then-hibernate.target"
        ];
        path = [ pkgs.coreutils pkgs.gawk ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${wifiRecover} resume";
          TimeoutStartSec = "3min";
        };
      };

      systemd.network = {
        enable = true;
        networks."30-wired" = {
          matchConfig.Name = ethDevice.${config.networking.hostName};
          address = [ staticIp.${config.networking.hostName} ];
          gateway = [ "172.17.0.254" ];
          dns = [ "127.0.0.1" ];
          networkConfig = {
            DHCP = "no";
          };
          linkConfig.RequiredForOnline = "yes";
        };
      };

      networking.wireless.iwd.enable = true;

      networking.wireless.iwd.settings = {
        Rank = {
          BandModifier2_4GHz = 0.1;
          BandModifier5GHz = 10.0;
        };
      };

      services = {
        avahi = {
          enable = true;
          publish = {
            enable = true;
            addresses = true;
          };
          nssmdns4 = true;
          nssmdns6 = true;
        };
      };

      programs.ssh.extraConfig = ''
        Host ssh.olympus.moe
          HostName ssh.olympus.moe
          Port 2222
      '';

      systemd.sockets.avahi-daemon = {
        wantedBy = lib.mkForce [ ];
        requiredBy = lib.mkForce [ ];
      };
      systemd.services.avahi-daemon.requires = lib.mkForce [ ];
    };

  flake.nixosModules.wireguardPeer =
    {
      inputs,
      config,
      lib,
      ...
    }:
    let
      IPv4Address = {
        "athena-nixos" = "192.168.10.1/32";
        "circe-nixos" = "192.168.10.2/32";
        "dionysus-nixos" = "192.168.10.3/32";
        "ariadne-nixos" = "192.168.10.4/32";
      };
      IPv6Address = {
        "athena-nixos" = "fd31:bf08:57cb::1/128";
        "circe-nixos" = "fd31:bf08:57cb::2/128";
        "dionysus-nixos" = "fd31:bf08:57cb::3/128";
        "ariadne-nixos" = "fd31:bf08:57cb::4/128";
      };
      publicKey = inputs.self.wireguardPublicKeys;
    in
    {
      config = lib.mkIf (builtins.elem config.networking.hostName (builtins.attrNames IPv4Address)) {
        sops.secrets."wireguard/${config.networking.hostName}/privateKey" = {
          mode = "640";
          owner = "systemd-network";
          group = "systemd-network";
          restartUnits = [ "systemd-networkd.service" ];
        };

        networking = {
          firewall = {
            allowedUDPPorts = [ 4500 ];
            extraCommands = ''
              iptables -A nixos-fw -s 192.168.10.254 -j nixos-fw-log-refuse
              ip6tables -A nixos-fw -s fd31:bf08:57cb::254 -j nixos-fw-log-refuse
            '';
          };
          networkmanager.unmanaged = [ "interface-name:wg0" ];
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

            routingPolicyRules = [
              {
                Priority = 97;
                FirewallMark = 42;
                Table = "main";
              }
            ];
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
              {
                #aether-nixos
                PublicKey = publicKey."aether-nixos";
                AllowedIPs = [
                  "192.168.10.0/24"
                  "fd31:bf08:57cb::/64"
                ];
                Endpoint = "vpn1.olympus.moe:4500";
                PersistentKeepalive = 25;
              }
              {
                #nyx-nixos
                PublicKey = publicKey."nyx-nixos";
                AllowedIPs = [
                  "fd31:bf08:57cb::253/128"
                  "192.168.10.253/32"
                ];
                Endpoint = "vpn2.olympus.moe:4500";
                PersistentKeepalive = 25;
              }
            ];
          };
        };

        systemd.services.systemd-networkd = {
          after = [ "sops-install-secrets.service" ];
          wants = [ "sops-install-secrets.service" ];
        };
      };
    };

  flake.nixosModules.mullvad = { config, pkgs, ... }: {
    services.mullvad-vpn.enable = true;

    systemd.services.mullvad-dns-config = {
      description = "Configure Mullvad VPN (DNS pinning to dnscrypt-proxy, allow local network)";
      after = [
        "mullvad-daemon.service"
        "dnscrypt-proxy.service"
      ];
      wants = [ "mullvad-daemon.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = 330;
      };
      script = ''
        until [ -n "$(${pkgs.dnsutils}/bin/dig @127.0.0.1 example.com +time=2 +tries=1 +short)" ]; do
          sleep 2
        done
        until ${config.services.mullvad-vpn.package}/bin/mullvad dns set custom 127.0.0.1; do
          sleep 2
        done
        until ${config.services.mullvad-vpn.package}/bin/mullvad lan set allow; do
          sleep 2
        done
        echo "Mullvad DNS pinned to local dnscrypt-proxy"
      '';
    };
  };

  flake.nixosModules.serverNetwork =
    {
      inputs,
      config,
      lib,
      ...
    }:
    let
      IPv4Address = {
        "nyx-nixos" = "172.17.100.1/16";
        "aether-nixos" = "107.174.36.56/24";
      };
      adapter = {
        "nyx-nixos" = "enp34s0";
        "aether-nixos" = "ens3";
      };
      gateway = {
        "nyx-nixos" = "172.17.0.254";
      };
      useDhcp = {
        "nyx-nixos" = false;
        "aether-nixos" = true;
      };
      nyxPorts = {
        allowedTCPPorts = [
          1147
          2283
          3210
          3211
          5006
          631
          8020
          8080
          8082
          8123
          8384
          8443
          853
          854
          25565
          42702
          7989
          8085
          25665
          25865
          3003
        ];
        allowedUDPPorts = [
          631
          853
          25665
          25865
        ];
      };
    in
    {
      imports = [ inputs.self.nixosModules.wireguardHost ];
      systemd.network = {
        enable = true;
        networks."${adapter.${config.networking.hostName}}" = {
          matchConfig.Name = adapter.${config.networking.hostName};
          networkConfig = {
            DHCP = if useDhcp.${config.networking.hostName} then "yes" else "no";
            DNS = "9.9.9.9";
          }
          // lib.optionalAttrs (!useDhcp.${config.networking.hostName}) {
            Address = IPv4Address.${config.networking.hostName};
            Gateway = gateway.${config.networking.hostName};
          };
          linkConfig.RequiredForOnline = "yes";
        };
      };

      networking.firewall = {
        checkReversePath = "loose";
        allowedTCPPorts = [
          22
          53
          8384
        ];
        allowedUDPPorts = [ 53 ];
      }
      // lib.optionalAttrs (config.networking.hostName == "nyx-nixos") {
        interfaces = {
          "enp34s0" = nyxPorts;
          "wg0" = nyxPorts;
        };
      };

      services.fail2ban = {
        enable = true;
        maxretry = 5;
        ignoreIP = lib.optionals (IPv4Address ? ${config.networking.hostName}) [
          IPv4Address.${config.networking.hostName}
        ];
        bantime = "24h";
        bantime-increment = {
          enable = true;
          formula = "ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)";
          # multipliers = "1 2 4 8 16 32 64";
          maxtime = "168h";
          overalljails = true;
        };
        jails = {
        };
      };
    };

  flake.nixosModules.dnscrypt-proxy =
    { lib, ... }:
    let
      hasIPv6Internet = true;
    in
    {
      services.dnscrypt-proxy = {
        enable = true;
        upstreamDefaults = false;
        settings = {
          listen_addresses = [ "127.0.0.1:5354" ];
          bootstrap_resolvers = [
            "9.9.9.9:53"
            "1.1.1.1:53"
            "8.8.8.8:53"
          ];
          ignore_system_dns = true;
          server_names = [
            "PuppyGirls-DNS"
            "PuppyGirlsLocal-DNS"
          ];

          static = {
            "PuppyGirls-DNS".stamp =
              "sdns://AgcAAAAAAAAADTEwNy4xNzQuMzYuNTYAEmRucy5wdXBweWdpcmxzLm5ldAovZG5zLXF1ZXJ5";
            "PuppyGirlsLocal-DNS".stamp =
              "sdns://AgcAAAAAAAAADDE3Mi4xNy4xMDAuMQAWZG5zLnB1cHB5Z2lybHMubmV0Ojg1NAovZG5zLXF1ZXJ5";

          };

          ipv6_servers = hasIPv6Internet;
          block_ipv6 = !(hasIPv6Internet);
          require_dnssec = false;
          require_nolog = false;
          require_nofilter = false;
        };
      };

      services.dnsproxy = {
        enable = true;
        settings = {
          "listen-addrs" = [ "127.0.0.1" ];
          "listen-ports" = [ 53 ];
          upstream = [ "127.0.0.1:5354" ];
          fallback = [
            "sdns://AgcAAAAAAAAABzEuMC4wLjEAEmRucy5jbG91ZGZsYXJlLmNvbQovZG5zLXF1ZXJ5"
            "sdns://AgMAAAAAAAAABzkuOS45LjkgsBkgdEu7dsmrBT4B4Ht-BQ5HPSD3n3vqQ1-v5DydJC8SZG5zOS5xdWFkOS5uZXQ6NDQzCi9kbnMtcXVlcnk"
          ];
          timeout = "3s";
        };
      };

      systemd.services.dnsproxy = {
        after = [ "dnscrypt-proxy.service" ];
        wants = [ "dnscrypt-proxy.service" ];
      };

      networking = {
        nameservers = [
          "127.0.0.1"
        ];

        networkmanager.insertNameservers = [ "127.0.0.1" ];

        dhcpcd.extraConfig = "nohook resolv.conf";
      };

    };

  flake.wireguardPublicKeys = {
    "athena-nixos" = "urmom";
    "circe-nixos" = "lBu6K0aoE95f9h/t1jB9Rgr9BTM8X9X0SYVE7hh6sxs=";
    "dionysus-nixos" = "OaaSw3LeEGFuiycxMWhz0i2UALIZnV8JZ1fl3nWpmlc=";
    "ariadne-nixos" = "ecyjWz3Fg8nsIwwL0MDpjr1/+U435ORR3YpVKgEeBiQ=";
    "aether-nixos" = "73mtIREvRqhfiUhfG47ITB3q+nMIO5M5+eVfIj9CslI=";
    "nyx-nixos" = "VOKzq4f1Sgj99NQxgldqX5PP2i3F+m+ttx2NIDzftHs=";
    "hermes" = "DWvPMpjBkUsCUshoL8BlIlKc/l2j7u2I8Up9b09UvA0=";
  };

  flake.nixosModules.syncthing = { config, ... }: let
    address = {
      "nyx-nixos" = "192.168.10.253";
    };
  in {
    services.syncthing = {
      enable = true;
      openDefaultPorts = true;

      guiAddress = "192.168.10.253:8384";
    };
  };
}
