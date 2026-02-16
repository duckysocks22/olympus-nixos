{
  services.adguardhome = {
    enable = true;
    host = "0.0.0.0";
    port = 3003;
    settings = {
      dns = {
        upstream_dns = [
          "9.9.9.9"
          "149.112.112.112"
        ];
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
