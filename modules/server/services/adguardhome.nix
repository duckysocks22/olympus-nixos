{
  services.adguardhome = {
    enable = true;
    host = "0.0.0.0";
    port = 3003;
    allowDHCP = true;
    settings = {
      dns = {
        upstream_dns = [
          "9.9.9.9"
          "149.112.112.112"
        ];
      };
      dhcp = {
        enabled = true;
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
        "https://adguardteam.github.io./HostlistsRegistry/assets/filter_9.txt"
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt"
        "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/light.txt"
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_50.txt"
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_71.txt"
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_30.txt"
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_7.txt"
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_6.txt"
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_47.txt"
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_59.txt"
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_24.txt"
      ];

      protection_enabled = false;
    };
  };
}
