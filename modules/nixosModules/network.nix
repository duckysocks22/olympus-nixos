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
        "ares-nixos" = "172.17.25.5/16";
      };
      autoconnect = {
        "athena-nixos" = "false";
        "circe-nixos" = "true";
        "ariadne-nixos" = "true";
        "dionysus-nixos" = "true";
        "ares-nixos" = "true";
      };
      ethDevice = lib.filterAttrs (_: v: v != null) {
        "ariadne-nixos" = "enp5s0";
        "athena-nixos" = null;
        "circe-nixos" = null;
        "dionysus-nixos" = null;
      };
      hasWiredEth = builtins.hasAttr config.networking.hostName ethDevice;
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
        case "$CONNECTION_ID" in
          bazinga) dns=172.17.100.1 ;;
          *) dns=127.0.0.1 ;;
        esac
        ${config.networking.networkmanager.package}/bin/nmcli con modify "$CONNECTION_ID" ipv4.ignore-auto-dns true ipv6.ignore-auto-dns true ipv4.dns "$dns" >/dev/null 2>&1 || true
        ${pkgs.systemd}/bin/resolvectl dns "$DEVICE_INTERFACE" "$dns" >/dev/null 2>&1 || true
      '';
    in
    {
      imports = [
        inputs.self.nixosModules.mullvad
        inputs.self.nixosModules.dnscrypt-proxy
        inputs.self.nixosModules.netbirdClient
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
            environmentFiles = [ "/run/wifi-recover/bazinga.env" ];
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
                dns = "172.17.100.1";
                ignore-auto-dns = true;
              };
              ipv6 = {
                addr-gen-mode = "stable-privacy";
                method = "auto";
                ignore-auto-dns = true;
              };
            };
          };
          unmanaged = lib.optionals hasWiredEth [ ethDevice.${config.networking.hostName} ];
        };
        firewall = {
          allowedTCPPorts = [
            4646
            8384
          ];
          allowedUDPPorts = [
            4646
            8384
          ];
        };
      };

      systemd.services.NetworkManager = {
        after = [ "iwd.service" ];
        wants = [ "iwd.service" ];
      };

      systemd.services.wifi-psk-env = {
        description = "Render bazinga PSK environment file for NetworkManager profile generation";
        wantedBy = [ "multi-user.target" ];
        after = [ "sops-install-secrets.service" ];
        wants = [ "sops-install-secrets.service" ];
        before = [ "NetworkManager-ensure-profiles.service" ];
        serviceConfig = {
          Type = "oneshot";
          RuntimeDirectory = "wifi-recover";
          RuntimeDirectoryPreserve = true;
          RuntimeDirectoryMode = "0700";
          UMask = "0077";
        };
        script = ''
          content="$(cat ${config.sops.secrets."networks/bazinga/pass".path})"
          case "$content" in
            BAZINGA_PSK=*) ;;
            *) content="BAZINGA_PSK=$content" ;;
          esac
          printf '%s\n' "$content" > /run/wifi-recover/bazinga.env
        '';
      };

      systemd.services.NetworkManager-ensure-profiles = {
        after = [ "wifi-psk-env.service" ];
        wants = [ "wifi-psk-env.service" ];
      };

      systemd.services.wifi-recover-boot =
        lib.mkIf (autoconnect.${config.networking.hostName} == "true")
          {
            description = "Ensure wifi autoconnect completes after declarative profiles are ensured";
            wantedBy = [ "multi-user.target" ];
            after = [
              "NetworkManager.service"
              "NetworkManager-ensure-profiles.service"
              "iwd.service"
            ];
            wants = [ "NetworkManager-ensure-profiles.service" ];
            path = [
              pkgs.coreutils
              pkgs.gawk
            ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${wifiRecover} boot";
              TimeoutStartSec = "3min";
            };
          };
      systemd.services.wifi-recover-resume =
        lib.mkIf (autoconnect.${config.networking.hostName} == "true")
          {
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
            path = [
              pkgs.coreutils
              pkgs.gawk
            ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${wifiRecover} resume";
              TimeoutStartSec = "3min";
            };
          };

      systemd.network = {
        enable = true;
        wait-online.enable = false;
      }
      // lib.optionalAttrs hasWiredEth {
        networks."30-wired" = {
          matchConfig.Name = ethDevice.${config.networking.hostName};
          address = [ staticIp.${config.networking.hostName} ];
          gateway = [ "172.17.0.254" ];
          dns = [ "172.17.100.1" ];
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
          853
          854
          25565
          42702
          7989
          8085
          25665
          25865
          3003
          3005
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
      imports = [
        inputs.self.nixosModules.aetherIngress
        inputs.self.nixosModules.netbirdClient
      ];
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
          "nb-wt0" = nyxPorts;
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
          sshd.settings = {
            enabled = true;
          };
        };
      };
    };

  flake.nixosModules.dnscrypt-proxy =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      hasIPv6Internet = true;

      # Peer-name resolution for the mesh: the netbird client runs the
      # *.olympus.netbird zone resolver on its own overlay IP (port 5053).
      # The dnscrypt-netbird-forward oneshot discovers this host's overlay
      # address at runtime and points dnscrypt at it, so peer names resolve
      # without per-host upkeep; hosts without netbird simply no-op.
      netbirdForwardRules = "/run/dnscrypt-netbird-forward/olympus.netbird.rules";
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
          ];

          static = {
            "PuppyGirls-DNS".stamp =
              "sdns://AgcAAAAAAAAADTEwNy4xNzQuMzYuNTYAEmRucy5wdXBweWdpcmxzLm5ldAovZG5zLXF1ZXJ5";
          };

          ipv6_servers = hasIPv6Internet;
          block_ipv6 = !(hasIPv6Internet);
          require_dnssec = false;
          require_nolog = false;
          require_nofilter = false;
          forwarding_rules = netbirdForwardRules;
        };
      };

      systemd.services.dnscrypt-netbird-forward = {
        description = "Point dnscrypt at netbird's mesh-zone resolver for *.olympus.netbird";
        after = [
          "dnscrypt-proxy.service"
          "netbird-wt0.service"
        ];
        wants = [ "netbird-wt0.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          TimeoutStartSec = 120;
          ExecStart = pkgs.writeShellScript "dnscrypt-netbird-forward" ''
            ip=${pkgs.iproute2}/bin/ip
            jq=${pkgs.jq}/bin/jq
            mkdir -p "$(dirname ${netbirdForwardRules})"
            for attempt in 1 2 3 4 5 6 7 8 9 10 11 12; do
              mesh_ip=$($ip -j -4 addr show nb-wt0 2>/dev/null | $jq -r '[.[] | .addr_info[] | select(.family == "inet") | .local] | .[0] // empty')
              if [ -n "$mesh_ip" ]; then
                echo "olympus.netbird $mesh_ip:5053" > ${netbirdForwardRules}
                systemctl restart dnscrypt-proxy.service
                echo "forwarding *.olympus.netbird $mesh_ip:5053"
                exit 0
              fi
              sleep 5
            done
            echo "no nb-wt0 address; netbird not connected, skipping rule (peer names unset)" >&2
            exit 0
          '';
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

  flake.nixosModules.syncthing =
    { config, ... }:
    let
      address = {
        "nyx-nixos" = "192.168.10.253";
      };
      hostSecrets = ../../secrets/${config.networking.hostName}.yaml;
    in
    {
      services.syncthing = {
        enable = true;
        overrideFolders = true;
        openDefaultPorts = true;

        cert = config.sops.secrets."syncthing/${config.networking.hostName}/cert".path;
        key = config.sops.secrets."syncthing/${config.networking.hostName}/key".path;

        settings = {
          devices = {
            circe-nixos = {
              id = "ECLW26H-2JWNNZX-YUWT42U-CYNARNX-SJRMMXA-XA2I7KD-ATCMTX2-4JXJNAP";
            };
            athena-nixos = {
              id = "JKIY2Y5-V62NP54-PUGNOIZ-N3VQ4QY-7LJ4T4T-WEQWEDX-B7RIP74-J24IGQM";
            };
            dionysus-nixos = {
              id = "AQSHDSY-3I6HO7B-XJTWCSU-5MBSCSL-AU4BWKN-PQUDFE2-YVBZT6R-25G7RAI";
            };
            ariadne-nixos = {
              id = "Z6NPUDI-PZ46LWD-6WJ2AN4-TFTS3ST-VSR4TBS-JSU73RB-MYOPXP7-2ISDWAR";
            };
            nyx-nixos = {
              id = "T5XG4ZF-FYS5II7-JJH5274-CZF2CDG-QDDTASR-FZH7FCO-TQA6UV2-KDFTYQB";
            };
          };
          folders = {
            "FFXIV" = {
              id = "FFXIV";
              path = "/media/hdd1/services/syncthing/ffxiv";
              devices = [
                "circe-nixos"
                "nyx-nixos"
                "dionysus-nixos"
                "athena-nixos"
                "ariadne-nixos"
              ];
              versioning = {
                type = "simple";
                params.keep = "10";
              };
              rescanIntervalS = 60;
              ignorePatterns = [
                "ffxivConfig/FFXIV.cfg"
                "ffxivConfig/FFXIV.cfg.old"
                "pluginConfigs/LightlessSync/tracelog"
                "!.stignore"
                "!accounts.json"
                "!secrets.json"
                "!cfgcopy"
                "!ffxivConfig"
                "!pluginConfigs"
                "!installedPlugins"
                "!dalamudConfig.json"
                "!dalamudUI.ini"
                "!launcherUI.ini"
                "!FFXIV_CHR004000174C7A37AE"
                "*"
              ];
            };
          };
        };
        # wildcard bind, listens whenever the overlay IP exists
        guiAddress = "0.0.0.0:8384";
        guiPasswordFile = "${config.sops.secrets."syncthing/pass".path}";

        settings.gui.user = "foxtrot";
      };

      systemd.services.syncthing = {
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 5;
        };
        unitConfig = {
          StartLimitIntervalSec = 0;
        };
      };

      sops.secrets."syncthing/${config.networking.hostName}/cert" = {
        owner = "syncthing";
        sopsFile = hostSecrets;
      };
      sops.secrets."syncthing/${config.networking.hostName}/key" = {
        owner = "syncthing";
        sopsFile = hostSecrets;
      };
      sops.secrets."syncthing/pass" = {
        owner = "syncthing";
        sopsFile = ../../secrets/common.yaml;
      };
    };

  flake.nixosModules.i2pd = { config, ... }: {
    services.i2pd = {
      enable = true;
      proto = {
        sam.enable = true;
        socksProxy.enable = true;
        httpProxy.enable = true;
      };
    };
  };

  # Dedicated point-to-point raw wireguard tunnel aether<->nyx that carries the
  # public ingress (caddy layer4 passthrough) into nyx independent of the
  # netbird overlay, so the control plane stays reachable even when netbird is
  # misbehaving. aether is the passive listener on its public address; nyx dials
  # out with keepalive.
  flake.nixosModules.relayTunnel =
    { config, lib, ... }:
    let
      relayIp = {
        "aether-nixos" = "192.168.200.1/30";
        "nyx-nixos" = "192.168.200.2/30";
      };
      listenPort = {
        "aether-nixos" = 51820;
        "nyx-nixos" = 51821;
      };
    in
    {
      config = lib.mkIf (builtins.hasAttr config.networking.hostName relayIp) {
        sops.secrets."wireguard/relay/${config.networking.hostName}/privateKey" = {
          sopsFile = ../../secrets/${config.networking.hostName}.yaml;
          mode = "640";
          owner = "systemd-network";
          group = "systemd-network";
          restartUnits = [ "systemd-networkd.service" ];
        };

        systemd.network = {
          enable = true;

          netdevs."40-wg-relay" = {
            netdevConfig = {
              Kind = "wireguard";
              Name = "wg-relay";
            };
            wireguardConfig = {
              ListenPort = listenPort.${config.networking.hostName};
              PrivateKeyFile =
                config.sops.secrets."wireguard/relay/${config.networking.hostName}/privateKey".path;
            };
            wireguardPeers =
              lib.optionals (config.networking.hostName == "nyx-nixos") [
                {
                  PublicKey = "V/yaorLg5c7cmCO+Ao47JN/1NYh5dXgtC7MXbaz8C2c=";
                  AllowedIPs = [ "192.168.200.1/32" ];
                  Endpoint = "107.174.36.56:51820";
                  PersistentKeepalive = 25;
                }
              ]
              ++ lib.optionals (config.networking.hostName == "aether-nixos") [
                {
                  PublicKey = "uRL+97TCAmkPwFQigHbnqbmW8NqZZ10X65j807aaklY=";
                  AllowedIPs = [ "192.168.200.2/32" ];
                }
              ];
          };

          networks."40-wg-relay" = {
            matchConfig.Name = "wg-relay";
            address = [ relayIp.${config.networking.hostName} ];
            networkConfig = {
              IPv4Forwarding = true;
              IPv6Forwarding = true;
            };
          };
        };

        systemd.services.systemd-networkd = {
          after = [ "sops-install-secrets.service" ];
          wants = [ "sops-install-secrets.service" ];
        };

        networking.firewall = lib.optionalAttrs (config.networking.hostName == "aether-nixos") {
          allowedUDPPorts = [ 51820 ];
        };
      };
    };

  flake.nixosModules.netbirdClient =
    { config, pkgs-unstable, ... }:
    let
      hostUsers = {
        athena-nixos = "foxtrot";
        circe-nixos = "foxtrot";
        dionysus-nixos = "deck";
        ariadne-nixos = "deck";
        nyx-nixos = "server";
        aether-nixos = "server";
        ares-nixos = "deck";
      };
    in
    {
      services.netbird = {
        package = pkgs-unstable.netbird;

        clients.wt0 = {
          config.ManagementURL = {
            Scheme = "https";
            Host = "netbird.olympus.moe:443";
          };

          login = {
            enable = true;
            setupKeyFile = config.sops.secrets."netbird/setupKey/${config.networking.hostName}".path;
            systemdDependencies = [ "sops-install-secrets.service" ];
          };

          port = 51821;
          ui.enable = true;
          openFirewall = true;
          openInternalFirewall = true;
        };
      };

      users.users.${hostUsers.${config.networking.hostName}}.extraGroups = [ "netbird-wt0" ];

      sops.secrets."netbird/setupKey/${config.networking.hostName}" = {
        sopsFile = ../../secrets/${config.networking.hostName}.yaml;
        mode = "640";
        owner = "netbird-wt0";
        group = "netbird-wt0";
        restartUnits = [ "netbird-wt0.service" ];
      };
    };
}
