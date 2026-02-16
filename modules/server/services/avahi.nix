{
  services.avahi = {
    enable = true;
    openFirewall = true;
    allowInterfaces = [
      "enp34s0"
      "tailscale0"
    ];
    nssmdns4 = true;
    nssmdns6 = true;
  };
}
