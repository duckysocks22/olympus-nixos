{ pkgs, ...}:
{
  environment.systemPackages = with pkgs; [ nextdns ];

  services.nextdns = {
    enable = true;
    arguments = [ "-config" "b8ee67" "-cache-size" "10MB" ];
  };

  systemd.services.nextdns-activate = {
    script = ''
      /run/current-system/sw/bin/nextdns activate
    '';
    after = [ "nextdns.service" ];
    wantedBy = [ "multi-user.target" ];
  };
}
