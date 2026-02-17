{ util, pkgs, lib, ... }:{
  services.avahi = {
    enable = true;
    openFirewall = true;
    allowInterfaces = [
      "enp34s0"
      "tailscale0"
    ];
    publish = {
      enable = true;
      domain = true;
    };
    nssmdns4 = true;
    nssmdns6 = true;
  };
}
