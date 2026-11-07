{ inputs, self, ... }:
{
  flake.nixosModules.mullvad =
    {
      config,
      pkgs,
      ...
    }:
    {
      services.mullvad-vpn.enable = true;

      systemd.services.mullvad-dns-config = {
        description = "Configure Mullvad VPN (DNS pinning to dnscrypt-proxy, allow local network)";
        after = [
          "mullvad-daemon.service"
          "dnscrypt-proxy.service"
        ];
        wants = [ "mullvad-daemon.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          TimeoutStartSec = 330;
        };
        script = ''
          until [ -n "$(${pkgs.dnsutils}/bin/dig @127.0.0.1 example.com +time=2 +tries=1 +short)" ]; do
            sleep 2
          done
          until ${config.services.mullvad-vpn.package}/bin/mullvad dns set custom 127.0.0.1; do
            sleep 2
          done
          until ${config.services.mullvad-vpn.package}/bin/mullvad lan set allow; do
            sleep 2
          done
          echo "Mullvad DNS pinned to local dnscrypt-proxy"
        '';
      };
    };
}
