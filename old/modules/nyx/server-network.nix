{ config, ... }:
{

  imports = [
    ./services/networking/netbird.nix
  ];
  systemd.network.enable = true;

  systemd.network.networks."enp34s0" = {
    matchConfig.Name = "enp34s0";
    networkConfig.DHCP = "no";
    networkConfig.Address = "172.17.100.1/16";
    networkConfig.Gateway = "172.17.0.254";
    networkConfig.DNS = "9.9.9.9";
    linkConfig.RequiredForOnline = "yes";
  };

  services.resolved = {
    enable = false;
    settings.Resolve = {
      DNSSEC = "true";
      Domains = [ "~." ];
      FallbackDNS = [ "9.9.9.9" ];
      DNSOverTLS = "true";
    };
  };

  networking.firewall.trustedInterfaces = [ "enp34s0" ];
  networking.firewall.checkReversePath = "loose";

  networking.firewall = {
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
