{ pkgs, pkgs-unstable, ... }:
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
