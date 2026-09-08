{ inputs, self, ... }: {
  flake.nixosModules.defaultNetwork = { config, pkgs, pkgs-unstable, lib, ... }: let
    staticIp = { "athena-nixos" = "172.17.25.1/16"; "circe-nixos" = "172.17.25.2/16"; "ariadne-nixos" = "172.17.25.3/16"; };
    autoconnect = { "athena-nixos" = "false"; "circe-nixos" = "true"; "ariadne-nixos" = "false"; };
  in {
    imports = [ inputs.self.nixosModules.mullvad inputs.self.nixosModules.dnscrypt-proxy ];

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

  flake.nixosModules.serverNetwork = { config, ... }: {
    systemd.network = {
      enable = true;
      networks."enp34s0" = {
        matchConfig.Name = "enp34s0";
        networkConfig.DHCP = "no";
        networkConfig.Address = "172.17.100.1/16";
        networkConfig.Gateway = "172.17.0.254";
        networkConfig.DNS = "9.9.9.9";
        linkConfig.RequiredForOnline = "yes";
      };
    };

    networking.firewall = {
      trustedInterfaces = [ "enp34s0" ];
      checkReversePath = "loose";
      allowedTCPPorts = [
        80
        443
        631
        8080
        7989
        8096
        3003
        853
        854
        2222
        25
        1883
        53
        67
        68
        3210
        3211
        config.services.home-assistant.config.http.server_port
        25665
        25666
        25765
        25766
        25865
        25866
        445
      ];
      allowedUDPPorts = [
        53
        853
        5353
        67
        68
        4001
        4002
        4003
      ];
    };

    services.fail2ban = {
      enable = true;
      maxretry = 5;
      ignoreIP = [
        "172.17.0.0/16"
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

  flake.nixosModules.dnscrypt-proxy = { lib, ... }: let
    hasIPv6Internet = true;
    StateDirectory = "dnscrypt-proxy";
  in {
    services.dnscrypt-proxy = {
      enable = true;
      upstreamDefaults = false;
      settings = {
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

      networkmanager.insertNameservers = [ "127.0.0.1" ];

      dhcpcd.extraConfig = "nohook resolv.conf";
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
