{ inputs, self, ... }: {
  flake.nixosModules.defaultNetwork = { config, pkgs, pkgs-unstable, lib, self, ... }: let
    staticIp = { "athena-nixos" = "172.17.25.1/16"; "circe-nixos" = "172.17.25.2/16"; };
    autoconnect = { "athena-nixos" = "false"; "circe-nixos" = "true"; };
  in {
    imports = [ self.nixosModules.mullvad self.nixosModules.dnscrypt-proxy ];

    networking = {
      networkmanager = {
        enable = true;
        wifi = {
          backend = "iwd";
          powersave = false;
          scanRandMacAddress = false;
        };
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
            };
          };
        };
      };
      firewall = {
        allowedTCPPorts = [ 4646 ];
        allowedUDPPorts = [ 4646 ];
      };
    };

    networking.wireless.iwd.enable = true;

    services = {
      avahi = {
        enable = true;
        publish = {
          enable = true;
          addresses = true;
        };
        nssmdns = true;
        nssmdns6 = true;
      };
      avahi-daemon.requires = lib.mkForce [ ];
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
  };

  flake.nixosModules.mullvad = { config, pkgs, ... }: {
    services.mullvad-vpn.enable = true;

    systemd.services.mullvad-dns-config = {
      description = "Pin Mullvad VPN DNS to local dnscrypt-proxy";
      after = [ "mullvad-daemon.service" ];
      wants = [ "mullvad-daemon.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = 60;
      };
      script = ''
        until ${config.services.mullvad-vpn.package}/bin/mullvad dns set custom 127.0.0.1; do
          sleep 1
        done
      '';
    };
  };

  flake.nixosModules.dnscrypt-proxy = { lib, ... }: let
    hasIPv6Internet = true;
    StateDirectory = "dnscrypt-proxy";
  in {
    services.dnscrypt-proxy = {
      enable = true;
      upstreamDefaults = false;
      settings = {
        boostrap_resolvers = [
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
            "sdns://AgcAAAAAAAAADTczLjc5LjE2NS4yMjMAEmRucy5wdXBweWdpcmxzLm5ldAovZG5zLXF1ZXJ5";
          "PuppyGirlsLocal-DNS".stamp =
            "sdns://AgcAAAAAAAAADDE3Mi4xNy4xMDAuMQAPbnl4LW5peG9zLmxvY2FsCi9kbnMtcXVlcnk";
        };

        ipv6_servers = hasIPv6Internet;
        block_ipv6 = !(hasIPv6Internet);
        require_dnssec = false;
        require_nolog = false;
        require_nofilter = false;
      };
    };

    networking = {
      nameservers = [ "127.0.0.1" "::1" ];

      networkmanager.insetNameservers = [ "127.0.0.1" ];

      dhcpd.extraConfig = "nohook resolve.conf";
    };

    systemd.services.dnscypt-proxy = {
      serviceConfig = {
        StateDirectory = StateDirectory;
        DynamicUser = lib.mkForce false;
        User = "root";
      };
    };
  };
}
