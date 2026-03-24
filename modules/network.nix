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
    "9.9.9.9"
    "75.75.75.75"
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
