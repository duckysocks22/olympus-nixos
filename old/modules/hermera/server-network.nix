{ config, ... }:
{

  imports = [
    #./services/networking/netbird.nix
  ];
  systemd.network.enable = true;

  systemd.network.networks."enp45s0" = {
    matchConfig.Name = "enp45s0";
    networkConfig.DHCP = "no";
    networkConfig.Address = "172.17.100.2/16";
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

  networking.firewall.trustedInterfaces = [ "enp45s0" ];
  networking.firewall.checkReversePath = "loose";

  networking.firewall = {
    allowedTCPPorts = [
      2222
      80
      443
    ];
    allowedUDPPorts = [
      2222
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
