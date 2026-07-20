{
  util,
  pkgs,
  lib,
  ...
}:
{
  services.avahi = {
    enable = true;
    openFirewall = true;
    allowInterfaces = [
      "enp34s0"
    ];
    publish = {
      enable = true;
      domain = true;
      userServices = true;
    };
    nssmdns4 = true;
  };
}
