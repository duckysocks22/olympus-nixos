{ inputs, self, ... }:
{
  flake.nixosModules.avahi =
    {
      util,
      pkgs,
      lib,
      config,
      ...
    }:
    {
      services.avahi =
        let
          adapter = {
            "aether-nixos" = "ens3";
            "nyx-nixos" = "enp34s0";
          };
        in
        {
          enable = true;
          openFirewall = true;
          allowInterfaces = [
            adapter.${config.networking.hostName}
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

    };
}
