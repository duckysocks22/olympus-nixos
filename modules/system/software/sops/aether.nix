{ inputs, self, ... }:
{
  flake.nixosModules.aetherSops =
    {
      inputs,
      config,
      ...
    }:
    let
      serverShared = ../../../../secrets/server-shared.yaml;
      common = ../../../../secrets/common.yaml;
    in
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      sops.defaultSopsFile = ../../../../secrets/aether-nixos.yaml;
      sops.defaultSopsFormat = "yaml";
      sops.useSystemdActivation = true;

      sops.age.keyFile = "${config.users.users.server.home}/.config/sops/age/keys.txt";

      sops.secrets."users/server" = {
        neededForUsers = true;
        sopsFile = serverShared;
      };

      sops.secrets."caddy/environment".sopsFile = serverShared;
      sops.secrets."caddy/ca-cert" = {
        owner = "caddy";
      };

      sops.secrets."attic/client-config" = {
        owner = config.users.users.server.name;
        sopsFile = common;
      };

      sops.secrets."wireguard/mullvad/privkey" = {
        mode = "640";
        owner = "systemd-network";
        group = "systemd-network";
        restartUnits = [ "systemd-networkd.service" ];
      };

      sops.secrets."netbird/coturn/pass" = {
        owner = "turnserver";
        group = "turnserver";
      };
    };
}
