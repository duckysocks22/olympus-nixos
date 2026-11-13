{ inputs, ... }:
{
  flake.nixosModules.netbirdCoturn =
    {
      config,
      ...
    }:
    {
      services.netbird.server.coturn = {
        enable = true;
        domain = "netbird.olympus.moe";
        passwordFile = config.sops.secrets."netbird/coturn/pass".path;
        openPorts = [ 3478 ];
      };

      networking.firewall.allowedUDPPortRanges = [
        {
          from = 49152;
          to = 65535;
        }
      ];

      systemd.services.coturn = {
        after = [ "sops-install-secrets.service" ];
        wants = [ "sops-install-secrets.service" ];
      };
    };
}
