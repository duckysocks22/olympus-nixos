{ pkgs, pkgs-unstable, ... }:
{

  imports = [
    ./netbird.nix
    ./dnscrypt-proxy.nix
  ];

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
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [
      "9.9.9.9"
      "1.1.1.1"
      "1.0.0.1"
    ];
    dnsovertls = "true";
  };

  networking.firewall = {
    allowedTCPPorts = [
      4646
    ];

    allowedUDPPorts = [
      4646
    ];
  };
}
