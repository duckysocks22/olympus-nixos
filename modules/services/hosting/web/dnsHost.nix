{ inputs, self, ... }:
{
  flake.nixosModules.dnsHost =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      meshIp = "192.168.10.253";
      # Served from aether's public ingress, not from nyx's 443 vhosts, so the
      # mesh instance must hand out the public records instead of the wildcard.
      publicNames = [
        "/netbird.olympus.moe/"
        "/dns.puppygirls.net/"
        "/ssh.olympus.moe/"
        "/vpn.olympus.moe/"
        "/www.olympus.moe/"
      ];
      meshConfig = pkgs.writeText "dnsmasq-mesh.conf" ''
        port=53
        listen-address=${meshIp}
        bind-dynamic
        no-resolv
        local-service
        server=127.0.0.1#53
        ${lib.concatMapStrings (name: "server=${name}127.0.0.1#53\n") publicNames}
        address=/olympus.moe/${meshIp}
        address=/puppygirls.net/${meshIp}
        local=/olympus.moe/
        local=/puppygirls.net/
      '';
    in
    {
      imports = [ inputs.self.nixosModules.adguardhome ];

      # LAN resolver; *.olympus.moe answers point at nyx's LAN address.
      services.dnsmasq = {
        enable = true;
        settings = {
          port = 53;
          listen-address = [ "172.17.100.1" ];
          # lets dnsmasq bind early / survive netbird bringing the overlay address up later
          bind-dynamic = true;
          no-resolv = true;
          local-service = true;
          server = [
            "127.0.0.1#53"
            "/ssh.olympus.moe/127.0.0.1#53"
            "/vpn.olympus.moe/127.0.0.1#53"
            "/www.olympus.moe/127.0.0.1#53"
          ];
          address = [
            "/olympus.moe/172.17.100.1"
            "/puppygirls.net/172.17.100.1"
          ];
          local = [
            "/olympus.moe/"
            "/puppygirls.net/"
          ];
        };
      };

      # NetBird peers are given this instance as their nameserver, so answers
      # have to be overlay-reachable. 172.17.100.1 is not: it is LAN-only and
      # firewalled off from non-172.17/16 sources, which blackholes netbird's
      # own control plane (management/signal/relay/TURN all live on
      # netbird.olympus.moe) as soon as the peer re-resolves it.
      systemd.services.dnsmasq-mesh = {
        description = "DNS resolver for netbird overlay peers (split-horizon answers)";
        after = [
          "network.target"
          "adguardhome.service"
        ];
        wants = [ "adguardhome.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.dnsmasq}/bin/dnsmasq -k --user=dnsmasq -C ${meshConfig}";
          Restart = "always";
          RestartSec = "2s";
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = true;
        };
      };

      # Router forwards 53 here; the LAN reaches this loop.
      networking.firewall.extraCommands = lib.mkAfter ''
        for proto in tcp udp; do
          iptables -C INPUT -d 172.17.100.1 -p $proto --dport 53 ! -s 172.17.0.0/16 -j DROP 2>/dev/null \
            || iptables -I INPUT 1 -d 172.17.100.1 -p $proto --dport 53 ! -s 172.17.0.0/16 -j DROP
        done
      '';
    };
}
