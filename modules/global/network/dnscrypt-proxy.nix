{ lib, ... }:
let
  hasIPv6Internet = true;
  StateDirectory = "dnscrypt-proxy";
in
{
  # See https://wiki.nixos.org/wiki/Encrypted_DNS
  services.dnscrypt-proxy2 = {
    enable = true;
    upstreamDefaults = false;
    settings = {
      bootstrap_resolvers = [
        "9.9.9.9:53"
        "1.1.1.1:53"
        "8.8.8.8:53"
      ];
      ignore_system_dns = true;
      server_names = [ "PuppyGirls-DNS" "PuppyGirlsLocal-DNS" ];

      static = {
        "PuppyGirls-DNS".stamp = "sdns://AgcAAAAAAAAADTczLjc5LjE2NS4yMjMAEmRucy5wdXBweWdpcmxzLm5ldAovZG5zLXF1ZXJ5";
        "PuppyGirlsLocal-DNS".stamp = "sdns://AgcAAAAAAAAADDE3Mi4xNy4xMDAuMQAPbnl4LW5peG9zLmxvY2FsCi9kbnMtcXVlcnk";
      };

      # Use servers reachable over IPv6 -- Do not enable if you don't have IPv6 connectivity
      ipv6_servers = hasIPv6Internet;
      block_ipv6 = ! (hasIPv6Internet);
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

  systemd.services.dnscrypt-proxy = {
    serviceConfig = {
      StateDirectory = StateDirectory;
      DynamicUser = lib.mkForce false;
      User = "root";
    };
  };
}

