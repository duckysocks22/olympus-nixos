{ inputs, self, ... }:
{
  flake.nixosModules.relayTunnel =
    {
      config,
      lib,
      ...
    }:
    let
      relayIp = {
        "aether-nixos" = "192.168.200.1/30";
        "nyx-nixos" = "192.168.200.2/30";
      };

      listenPort = {
        "aether-nixos" = 51820;
        "nyx-nixos" = 51821;
      };
    in
    {
      config = lib.mkIf (builtins.hasAttr config.networking.hostName relayIp) {
        sops.secrets."wireguard/relay/${config.networking.hostName}/privateKey" = {
          sopsFile = ../../../secrets/${config.networking.hostName}.yaml;
          mode = "640";
          owner = "systemd-network";
          group = "systemd-network";
          restartUnits = [ "systemd-networkd.service" ];
        };

        systemd.network = {
          enable = true;

          netdevs."40-wg-relay" = {
            netdevConfig = {
              Kind = "wireguard";
              Name = "wg-relay";
            };
            wireguardConfig = {
              ListenPort = listenPort.${config.networking.hostName};
              PrivateKeyFile =
                config.sops.secrets."wireguard/relay/${config.networking.hostName}/privateKey".path;
            };
            wireguardPeers =
              lib.optionals (config.networking.hostName == "nyx-nixos") [
                {
                  PublicKey = "V/yaorLg5c7cmCO+Ao47JN/1NYh5dXgtC7MXbaz8C2c=";
                  AllowedIPs = [ "192.168.200.1/32" ];
                  Endpoint = "107.174.36.56:51820";
                  PersistentKeepalive = 25;
                }
              ]
              ++ lib.optionals (config.networking.hostName == "aether-nixos") [
                {
                  PublicKey = "uRL+97TCAmkPwFQigHbnqbmW8NqZZ10X65j807aaklY=";
                  AllowedIPs = [ "192.168.200.2/32" ];
                }
              ];
          };

          networks."40-wg-relay" = {
            matchConfig.Name = "wg-relay";
            address = [ relayIp.${config.networking.hostName} ];
            networkConfig = {
              IPv4Forwarding = true;
              IPv6Forwarding = true;
            };
          };
        };

        systemd.services.systemd-networkd = {
          after = [ "sops-install-secrets.service" ];
          wants = [ "sops-install-secrets.service" ];
        };

        networking.firewall = lib.optionalAttrs (config.networking.hostName == "aether-nixos") {
          allowedUDPPorts = [ 51820 ];
        };
      };
    };
}
