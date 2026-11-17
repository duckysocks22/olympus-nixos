{ inputs, self, ... }:
{
  flake.nixosModules.dnscrypt-proxy =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      hasIPv6Internet = true;
      netbirdForwardRules = "/run/dnscrypt-netbird-forward/olympus.netbird.rules";
    in
    {
      services.dnscrypt-proxy = {
        enable = true;
        upstreamDefaults = false;
        settings = {
          listen_addresses = [ "127.0.0.1:5354" ];
          bootstrap_resolvers = [
            "9.9.9.9:53"
            "1.1.1.1:53"
            "8.8.8.8:53"
          ];
          ignore_system_dns = true;
          server_names = [
            "PuppyGirls-DNS"
          ];

          static = {
            "PuppyGirls-DNS".stamp =
              "sdns://AgcAAAAAAAAADTEwNy4xNzQuMzYuNTYAEmRucy5wdXBweWdpcmxzLm5ldAovZG5zLXF1ZXJ5";
          };

          ipv6_servers = hasIPv6Internet;
          block_ipv6 = !(hasIPv6Internet);
          require_dnssec = false;
          require_nolog = false;
          require_nofilter = false;
          forwarding_rules = netbirdForwardRules;
        };
      };

      systemd.services.dnscrypt-netbird-forward = {
        description = "Point dnscrypt at netbird's mesh-zone resolver for *.olympus.netbird";
        after = [
          "dnscrypt-proxy.service"
          "netbird-wt0.service"
        ];
        wants = [ "netbird-wt0.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          TimeoutStartSec = 120;
          ExecStart = pkgs.writeShellScript "dnscrypt-netbird-forward" ''
            ip=${pkgs.iproute2}/bin/ip
            jq=${pkgs.jq}/bin/jq
            mkdir -p "$(dirname ${netbirdForwardRules})"
            for attempt in 1 2 3 4 5 6 7 8 9 10 11 12; do
              mesh_ip=$($ip -j -4 addr show nb-wt0 2>/dev/null | $jq -r '[.[] | .addr_info[] | select(.family == "inet") | .local] | .[0] // empty')
              if [ -n "$mesh_ip" ]; then
                echo "olympus.netbird $mesh_ip:5053" > ${netbirdForwardRules}
                systemctl restart dnscrypt-proxy.service
                echo "forwarding *.olympus.netbird $mesh_ip:5053"
                exit 0
              fi
              sleep 5
            done
            echo "no nb-wt0 address; netbird not connected, skipping rule (peer names unset)" >&2
            exit 0
          '';
        };
      };

      services.dnsproxy = {
        enable = true;
        settings = {
          "listen-addrs" = [ "127.0.0.1" ];
          "listen-ports" = [ 53 ];
          upstream = [ "127.0.0.1:5354" ];
          fallback = [
            "sdns://AgcAAAAAAAAABzEuMC4wLjEAEmRucy5jbG91ZGZsYXJlLmNvbQovZG5zLXF1ZXJ5"
            "sdns://AgMAAAAAAAAABzkuOS45LjkgsBkgdEu7dsmrBT4B4Ht-BQ5HPSD3n3vqQ1-v5DydJC8SZG5zOS5xdWFkOS5uZXQ6NDQzCi9kbnMtcXVlcnk"
          ];
          timeout = "3s";
        };
      };

      systemd.services.dnsproxy = {
        after = [ "dnscrypt-proxy.service" ];
        wants = [ "dnscrypt-proxy.service" ];
      };

      networking = {
        nameservers = [
          "127.0.0.1"
        ];

        networkmanager.insertNameservers = [ "127.0.0.1" ];

        dhcpcd.extraConfig = "nohook resolv.conf";
      };
    };
}
