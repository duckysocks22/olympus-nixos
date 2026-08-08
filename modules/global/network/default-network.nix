{
  config,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  staticIp = {
    "athena-nixos" = "172.17.25.1/16";
    "circe-nixos" = "172.17.25.2/16";
  };
  autoconnect = {
    "athena-nixos" = "false";
    "circe-nixos" = "true";
  };
in
{

  imports = [
    ./netbird.nix
    ./dnscrypt-proxy.nix
    ./mullvad.nix
  ];

  networking.networkmanager = {
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

  networking.wireless.iwd.enable = true;

  services.tailscale = {
    enable = false;
  };

  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      addresses = true;
    };
    nssmdns4 = true;
    nssmdns6 = true;
  };

  services.resolved = {
    enable = false;
    settings.Resolve = {
      DNSSEC = "true";
      Domains = "~.";
      FallbackDNS = "9.9.9.9 1.1.1.1 1.0.0.1";
      DNSOverTLS = "true";
    };
  };

  programs.ssh.extraConfig = ''
    Host ssh.olympus.moe
      HostName ssh.olympus.moe
      Port 2222
  '';

  networking.firewall = {
    allowedTCPPorts = [
      4646
    ];

    allowedUDPPorts = [
      4646
    ];
  };
}
