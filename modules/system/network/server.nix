{ inputs, self, ... }:
{
  flake.nixosModules.serverNetwork =
    {
      inputs,
      config,
      lib,
      ...
    }:
    let
      IPv4Address = {
        "nyx-nixos" = "172.17.100.1/16";
        "aether-nixos" = "107.174.36.56/24";
      };
      adapter = {
        "nyx-nixos" = "enp34s0";
        "aether-nixos" = "ens3";
      };
      gateway = {
        "nyx-nixos" = "172.17.0.254";
      };
      useDhcp = {
        "nyx-nixos" = false;
        "aether-nixos" = true;
      };
      nyxPorts = {
        allowedTCPPorts = [
          1147
          2283
          3210
          3211
          5006
          631
          8020
          8080
          8082
          8123
          8384
          853
          854
          25565
          42702
          7989
          8085
          25665
          25865
          3003
          3005
        ];
        allowedUDPPorts = [
          631
          853
          25665
          25865
        ];
      };
    in
    {
      imports = [
        inputs.self.nixosModules.aetherIngress
        inputs.self.nixosModules.netbirdClient
      ];

      systemd.network = {
        enable = true;
        networks."${adapter.${config.networking.hostName}}" = {
          matchConfig.Name = adapter.${config.networking.hostName};
          networkConfig = {
            DHCP = if useDhcp.${config.networking.hostName} then "yes" else "no";
            DNS = "9.9.9.9";
          }
          // lib.optionalAttrs (!useDhcp.${config.networking.hostName}) {
            Address = IPv4Address.${config.networking.hostName};
            Gateway = gateway.${config.networking.hostName};
          };
          linkConfig.RequiredForOnline = "yes";
        };
      };

      networking.firewall = {
        checkReversePath = "loose";
        allowedTCPPorts = [
          22
          53
          8384
        ];
        allowedUDPPorts = [ 53 ];
      }
      // lib.optionalAttrs (config.networking.hostName == "nyx-nixos") {
        interfaces = {
          "enp34s0" = nyxPorts;
          "nb-wt0" = nyxPorts;
        };
      };

      services.fail2ban = {
        enable = true;
        maxretry = 5;

        ignoreIP = lib.optionals (IPv4Address ? ${config.networking.hostName}) [
          IPv4Address.${config.networking.hostName}
        ];

        bantime = "24h";

        bantime-increment = {
          enable = true;
          formula = "ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)";
          # multipliers = "1 2 4 8 16 32 64";
          maxtime = "168h";
          overalljails = true;
        };

        jails = {
          sshd.settings = {
            enabled = true;
          };
        };
      };
    };
}
