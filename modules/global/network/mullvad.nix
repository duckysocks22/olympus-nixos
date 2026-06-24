{ pkgs, ... }:
{
  services.mullvad-vpn = {
    enable = true;
  };

  systemd.services.mullvad-dns-config = {
    description = "Pin Mullvad VPN DNS to local dnscrypt-proxy";
    after    = [ "mullvad-daemon.service" ];
    wants    = [ "mullvad-daemon.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      until ${pkgs.mullvad-vpn}/bin/mullvad dns set custom 127.0.0.1; do
        sleep 1
      done
    '';
  };
}

