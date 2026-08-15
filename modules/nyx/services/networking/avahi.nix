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

  systemd.sockets.avahi-daemon = {
    wantedBy = lib.mkForce [ ];
    requiredBy = lib.mkForce [ ];
  };
  systemd.services.avahi-daemon.requires = lib.mkForce [ ];
}
