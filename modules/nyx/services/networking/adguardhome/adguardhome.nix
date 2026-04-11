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
      };
      tls = {
        enabled = false;
        server_name = "nyx-nixos.local";
        force_https = false;
        port_https = 854;
        port_dns_over_tls = 853;
        certificate_path = "/var/lib/acme/puppygirls.net/cert.pem";
        private_key_path = "/var/lib/acme/puppygirls.net/key.pem";
      };
      dhcp = {
        enabled = false;
        interface_name = "enp34s0";
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
      };

      trusted_proxies = [ 127.0.0.1 ];

      filters = map(url: { enabled = true; url = url; }) [
        "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt"
        "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/refs/heads/master/SmartTV.txt"
        "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.txt"
        "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/popupads.txt"
      ];

      whitelist_filters = map(url: { enabled = true; url = url; }) [
        "https://dawn.wine/foxtrottt/olympus-nixos/raw/branch/main/modules/nyx/services/networking/adguardhome/allowlist.txt"
      ];

      protection_enabled = false;
    };
  };
}
