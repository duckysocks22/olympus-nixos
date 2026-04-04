{ inputs, ... }:
{
  flake.nixosModules.default-network = { pkgs, ...}: {
    
    networking.networkmanager.enable = true;
    programs.nm-applet.enable = true;

    services.openssh.enable = true;

    services.tailscale = {
      enable = true;
    };

    services.avahi = {
      enable = true;
      public = {
        enable = true;
        addresses = true;
      };
      nssmdns4 = true;
      nssmdns6 = true;
    };

    services.resolved = {
      enable = true;
      dnssec = "true";
      domains = [ "~." ];
      fallbackDns = [
        "172.17.100.1"
        "45.90.28.0#b8ee67.dns.nextdns.io"
        "2a07:a8c0::#b8ee67.dns.nextdns.io"
        "45.90.30.0#b8ee67.dns.nextdns.io"
        "2a07:a8c1::#b8ee67.dns.nextdns.io"
        "https://dns.nextdns.io/b8ee67"
        "9.9.9.9"
        "1.1.1.1"
        "1.0.0.1"
      ];
      dnsovertls = "false";
    };
  };
}
