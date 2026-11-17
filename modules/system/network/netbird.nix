{ inputs, self, ... }:
{
  flake.nixosModules.netbirdClient =
    {
      config,
      pkgs-unstable,
      ...
    }:
    let
      hostUsers = {
        athena-nixos = "foxtrot";
        circe-nixos = "foxtrot";
        dionysus-nixos = "deck";
        ariadne-nixos = "deck";
        nyx-nixos = "server";
        aether-nixos = "server";
      };
    in
    {
      services.netbird = {
        package = pkgs-unstable.netbird;

        clients.wt0 = {
          config.ManagementURL = {
            Scheme = "https";
            Host = "netbird.olympus.moe:443";
          };

          login = {
            enable = true;
            setupKeyFile = config.sops.secrets."netbird/setupKey/${config.networking.hostName}".path;
            systemdDependencies = [ "sops-install-secrets.service" ];
          };

          port = 51821;
          ui.enable = true;
          openFirewall = true;
          openInternalFirewall = true;
        };
      };

      users.users.${hostUsers.${config.networking.hostName}}.extraGroups = [ "netbird-wt0" ];

      sops.secrets."netbird/setupKey/${config.networking.hostName}" = {
        sopsFile = ../../../secrets/${config.networking.hostName}.yaml;
        mode = "640";
        owner = "netbird-wt0";
        group = "netbird-wt0";
        restartUnits = [ "netbird-wt0.service" ];
      };
    };
}
