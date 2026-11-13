{ inputs, ... }:
{
  flake.nixosModules.aetherIngress =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = lib.mkIf (config.networking.hostName == "aether-nixos") {
        networking.nat = {
          enable = true;
          enableIPv6 = true;
          externalInterface = "ens3";
          internalInterfaces = [ "nb-wt0" ];
          forwardPorts = [
            {
              sourcePort = 853;
              destination = "192.168.10.253:853";
            }
            {
              sourcePort = 853;
              proto = "udp";
              destination = "192.168.10.253:853";
            }
            {
              sourcePort = 25565;
              destination = "192.168.10.253:25665";
            }
            {
              sourcePort = 25665;
              destination = "192.168.10.253:25665";
            }
            {
              sourcePort = 25865;
              destination = "192.168.10.253:25865";
            }
          ];
        };

        networking.firewall = {
          allowedUDPPorts = [ 853 ];
          allowedTCPPorts = [
            853
            25565
            25665
            25865
          ];
        };

        # No .network file for nb-wt0: matching one makes networkd claim the
        # link and flush netbird's direct netlink address assignment. Forwarding
        # is covered by the global ip_forward sysctls (needed anyway for the
        # mullvad exit module); the iif policy rule lives in iproute2 setup.
        boot.kernel.sysctl = {
          "net.ipv4.ip_forward" = true;
          "net.ipv6.conf.all.forwarding" = true;
        };

        systemd.services.netbird-mullvad-rule = {
          description = "Policy rule: netbird overlay traffic routed via Mullvad tunnel";
          after = [
            "network.target"
            "netbird-wt0.service"
          ];
          wants = [ "netbird-wt0.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "nb-mullvad-rule" ''
              #!${pkgs.stdenv.shell}
              ip=${pkgs.iproute2}/bin/ip
              for attempt in 1 2 3 4 5 6 7 8 9 10; do
                "$ip" -4 rule add iif nb-wt0 table 51820 priority 100 2>/dev/null || true
                "$ip" -6 rule add iif nb-wt0 table 51820 priority 100 2>/dev/null || true
                if "$ip" -4 rule show | grep -q "iif nb-wt0"; then
                  echo "policy rules installed"
                  exit 0
                fi
                sleep 3
              done
              echo "failed to install nb-wt0 policy rules" >&2
              exit 1
            '';
            ExecStop = pkgs.writeShellScript "nb-mullvad-rule-stop" ''
              ${pkgs.iproute2}/bin/ip -4 rule del iif nb-wt0 table 51820 priority 100 2>/dev/null || true
              ${pkgs.iproute2}/bin/ip -6 rule del iif nb-wt0 table 51820 priority 100 2>/dev/null || true
            '';
          };
        };
      };
    };
}
