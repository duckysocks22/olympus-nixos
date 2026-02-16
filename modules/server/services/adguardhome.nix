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
      ];
    };
  };
}
