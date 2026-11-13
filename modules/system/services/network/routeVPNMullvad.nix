{ inputs, ... }:
{
  flake.nixosModules.routeVPNMullvad =
    {
      config,
      pkgs,
      ...
    }:
    {
      systemd.network = {
        netdevs."60-wg-mullvad1" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "wg-mullvad1";
          };
          wireguardConfig = {
            PrivateKeyFile = config.sops.secrets."wireguard/mullvad/privkey".path;
            FirewallMark = 51820;
            RouteTable = 51820;
          };
          wireguardPeers = [
            {
              PublicKey = "HjcUGVDXWdrRkaKNpc/8494RM5eICO6DPyrhCtTv9Ws=";
              AllowedIPs = [
                "0.0.0.0/0"
                "::/0"
              ];
              Endpoint = "143.244.47.78:3489";
            }
          ];
        };

        networks."60-wg-mullvad1" = {
          matchConfig.Name = "wg-mullvad1";
          address = [
            "10.72.161.131/32"
            "fc00:bbbb:bbbb:bb01::9:a182/128"
          ];
        };

      };

      networking.iproute2.rttablesExtraConfig = ''
        100 nb-wt0-mullvad
      '';

      networking.nat = {
        extraCommands = ''
          # netbird overlay -> mullvad exit masquerade
          iptables -w -t nat  -A nixos-nat-post -o wg-mullvad1 -i nb-wt0  -j MASQUERADE
          ip6tables -w -t nat -A nixos-nat-post -o wg-mullvad1 -i nb-wt0  -j MASQUERADE
        '';

        extraStopCommands = ''
          # netbird overlay
          iptables -w -t nat  -D nixos-nat-post -o wg-mullvad1 -i nb-wt0  -j MASQUERADE || true
          ip6tables -w -t nat -D nixos-nat-post -o wg-mullvad1 -i nb-wt0  -j MASQUERADE || true
        '';
      };

      sops.secrets."netbird/api/pat" = {
        sopsFile = ../../../../secrets/${config.networking.hostName}.yaml;
        mode = "640";
        owner = "root";
        group = "root";
      };

      systemd.services.netbird-mullvad-route = {
        description = "Provision Mullvad exit-node route in netbird management (idempotent)";
        after = [
          "network-online.target"
          "netbird-management.service"
        ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeScript "netbird-mullvad-route.sh" ''
            #!${pkgs.bash}/bin/bash
            set -uo pipefail

            API=https://netbird.olympus.moe/api
            PAT=$(<${config.sops.secrets."netbird/api/pat".path})
            curl=${pkgs.curl}/bin/curl
            jq=${pkgs.jq}/bin/jq
            auth=(-H "Authorization: Token $PAT")

            req() {
              local m=$1 path=$2 body=''${3-} out code
              if [ -n "$body" ]; then
                out=$($curl -sS --show-error -w "\n%{http_code}" -X "$m" "''${auth[@]}" -H "Content-Type: application/json" -d "$body" "$API$path") \
                  || { echo "request to $path failed: $out" >&2; exit 1; }
              else
                out=$($curl -sS --show-error -w "\n%{http_code}" "''${auth[@]}" "$API$path") \
                  || { echo "request to $path failed" >&2; exit 1; }
              fi
              code="''${out##*$'\n'}"
              body="''${out%$'\n'*}"
              if [ "$code" -lt 200 ] || [ "$code" -ge 400 ]; then
                echo "API $m $path -> HTTP $code: $(printf '%s' "$body" | head -c 300)" >&2
                exit 1
              fi
              printf '%s' "$body"
            }

            until $curl -sf "''${auth[@]}" "$API/peers" >/dev/null 2>&1; do
              echo "management API unreachable, retrying"
              sleep 5
            done

            peer=$(req GET /peers | $jq -c '[.[] | select(.name=="aether-nixos")] | .[0] // empty')
            [ -n "$peer" ] || { echo "aether-nixos peer not found"; exit 1; }
            peer_id=$($jq -rn --argjson p "$peer" '$p.id')

            dist=$(req GET /groups | $jq -c '[.[] | select(.name=="mullvad-exit-users")] | .[0] // empty')
            if [ -z "$dist" ]; then
              dist=$(req POST /groups '{"name":"mullvad-exit-users"}')
            fi
            dist_id=$($jq -rn --argjson g "$dist" '$g.id')
            [ -n "$dist_id" ] || { echo "failed to ensure distribution group"; exit 1; }

            body=$($jq -nc --arg dist "$dist_id" --arg peer "$peer_id" '{
              description: "Mullvad exit node (aether)",
              network_id: "mullvad-exit",
              enabled: true,
              network: "0.0.0.0/0",
              metric: 9999,
              masquerade: true,
              keep_route: false,
              skip_auto_apply: true,
              groups: [$dist],
              peer: $peer
            }')

            existing=$(req GET /routes | $jq -c '[.[] | select(.network_id=="mullvad-exit")] | .[0] // empty')
            if [ -n "$existing" ]; then
              rid=$($jq -rn --argjson e "$existing" '$e.id')
              req PUT /routes/$rid "$body" >/dev/null
              echo "exit route updated"
            else
              req POST /routes "$body" >/dev/null
              echo "exit route created"
            fi
          '';
        };
      };
    };
}
