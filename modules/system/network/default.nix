{ inputs, self, ... }:
{
  flake.nixosModules.defaultNetwork =
    {
      config,
      pkgs,
      pkgs-unstable,
      lib,
      options,
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
          nssmdns4 = true;
          nssmdns6 = true;
        }
        // lib.optionalAttrs (options.services.avahi ? settings) {
          settings.publish = {
            disable-publishing = false;
            publish-addresses = true;
          };
        }
        // lib.optionalAttrs (!(options.services.avahi ? settings)) {
          publish = {
            enable = true;
            addresses = true;
          };
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
}
