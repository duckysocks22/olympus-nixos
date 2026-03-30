{ pkgs, pkgs-unstable, ... }:
{

  services.tailscale = {
    enable = true;
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

  networking.nameservers = [
    "45.90.28.0#b8ee67.dns.nextdns.io"
    "2a07:a8c0::#b8ee67.dns.nextdns.io"
    "45.90.30.0#b8ee67.dns.nextdns.io"
    "2a07:a8c1::#b8ee67.dns.nextdns.io"
  ];

  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [
      "9.9.9.9"
      "75.75.75.75"
    ];
    dnsovertls = "true";
  };
}
