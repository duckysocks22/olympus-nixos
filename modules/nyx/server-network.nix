{ config, ... }:
{

  imports = [
    ./services/networking/netbird.nix
  ];

  services.tailscale = {
    enable = true;
  };

  systemd.network.enable = true;

  systemd.network.networks."enp34s0" = {
    matchConfig.Name = "enp34s0";
    networkConfig.DHCP = "no";
    networkConfig.Address = "172.17.100.1/16";
    networkConfig.Gateway = "172.17.0.254";
    networkConfig.DNS = "9.9.9.9";
    linkConfig.RequiredForOnline = "yes";
  };

  systemd.network.networks."tailscale0" = {
    matchConfig.Name = "tailscale0";
    networkConfig.DHCP = "ipv4";
    linkConfig.RequiredForOnline = "no";
  };

  services.resolved = {
    enable = false;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [ "9.9.9.9" ];
    dnsovertls = "true";
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" "enp34s0" ];
  networking.firewall.checkReversePath = "loose";

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
      5353
      631
      8080
      7989
      8096
      8971
      3003
      53
      853
      1984
      3389
      22
      25
      1883
      53
      5353
      67
      68
      3210
      3211
      config.services.home-assistant.config.http.server_port
      25565
      25575
      25665
      25666
      445
    ];
    allowedUDPPorts = [
      config.services.tailscale.port
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
      "10.0.0.0/16"
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
}
