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
}
