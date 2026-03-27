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
          "75.75.75.75"
        ];
        bootstrap_dns = [
          "9.9.9.9"
          "75.75.75.75"
        ];
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

      filters = map(url: { enabled = true; url = url; }) [
        "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt"
        "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/refs/heads/master/SmartTV.txt"
        "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.txt"
        "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/spam-tlds.txt"
      ];

      whitelist_filters = map(url: { enabled = true; url = url; }) [
        "https://dawn.wine/foxtrottt/olympus-nixos/raw/branch/main/modules/server/services/networking/adguardhome/allowlist.txt"
      ];

      protection_enabled = false;
    };
  };
}
