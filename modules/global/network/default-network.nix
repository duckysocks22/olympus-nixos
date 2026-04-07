{ pkgs, pkgs-unstable, ... }:
{

  imports = [
    ./netbird.nix
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

  networking.nameservers = [
  ];

  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [
      "172.17.100.1"
      "73.79.165.223"
      "9.9.9.9"
      "1.1.1.1"
      "1.0.0.1"
    ];
    dnsovertls = "true";
  };
}
