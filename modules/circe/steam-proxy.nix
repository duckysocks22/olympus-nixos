{ pkgs, lib, ... }:
let
  proxychainsCfg = pkgs.writeText "proxychains-steam.conf" ''
    strict_chain
    proxy_dns
    quiet_mode
    tcp_read_time_out 15000
    tcp_connect_time_out 8000
    [ProxyList]
    socks5  127.0.0.1  1081
  '';
  privoxyCfg = pkgs.writeText "privoxy-steam.conf" ''
    listen-address  127.0.0.1:8118
    forward         /  .
    logdir          /tmp
    logfile         privoxy-steam.log
    debug           0
  '';
in
{
  systemd.services.privoxy-steam = {
    description = "Privoxy for Steam cloud saves";
    after = [
      "network.target"
      "autossh-steam-proxy.service"
    ];
    wantedBy = [ "multi-user.target" ];
    environment.PROXYCHAINS_CONF_FILE = "${proxychainsCfg}";
    serviceConfig = {
      ExecStart = "${pkgs.proxychains}/bin/proxychains4 ${pkgs.privoxy}/bin/privoxy --no-daemon ${privoxyCfg}";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  programs.steam.package = lib.mkForce (
    pkgs.steam.override {
      extraBwrapArgs = [
        "--bind"
        "/dev/null"
        "/etc/ld-nix.so.preload"
        "--setenv"
        "http_proxy"
        "http://127.0.0.1:8118"
        "--setenv"
        "HTTP_PROXY"
        "http://127.0.0.1:8118"
        "--setenv"
        "https_proxy"
        "http://127.0.0.1:8118"
        "--setenv"
        "HTTPS_PROXY"
        "http://127.0.0.1:8118"
      ];
    }
  );
}
