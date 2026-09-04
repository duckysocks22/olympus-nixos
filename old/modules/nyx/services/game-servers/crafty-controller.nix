{ lib, config, ... }:
{
  imports = [ ../../../packages/crafty-controller/crafty-service.nix ];

  services.crafty-controller = {
    enable = false;
    dataDir = "/media/hdd1/game-servers/crafty";
    settings = {
      delete_default_json = "true";
      https_port = 8443;
    };
  };

  # crafty-controller spins in a tight loop printing "*** Unknown syntax: EOF"
  # when it reads EOF from its stdin (/dev/null). This produces tens of thousands
  # of journal entries per minute and will flood the journal buffer into OOM.
  # Cap it to 500 messages per 30 s — enough to see real events, not the flood.
  # (only applies when the service is enabled; unconditional overrides create a
  # stub unit with no ExecStart= which systemd rejects as a bad-unit-file)
  systemd.services.crafty-controller.serviceConfig =
    lib.mkIf config.services.crafty-controller.enable
      {
        LogRateLimitIntervalSec = "30s";
        LogRateLimitBurst = 500;
      };
}
