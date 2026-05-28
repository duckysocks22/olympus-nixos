{ config, lib, pkgs, ... }:
let
  cfg = config.services.crafty-controller;
  crafty-pkg = pkgs.callPackage ./crafty-pkg.nix {};
in
{
  options.services.crafty-controller = {
    enable = lib.mkEnableOption "Crafty Controller Minecraft server management panel";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/crafty-controller";
      description = ''
        Directory where Crafty stores its application code, server files, config,
        and logs. Override this to place data on a separate volume.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "crafty";
      description = "User account Crafty Controller runs under.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "crafty";
      description = "Group Crafty Controller runs under.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open TCP port 8443 in the firewall for the Crafty web interface.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
    };

    users.groups.${cfg.group} = {};

    # Create the data directory before the service starts.
    # The wrapper's install/upgrade logic requires it to be writable by cfg.user.
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.crafty-controller = {
      description = "Crafty Controller Minecraft server management panel";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      # The wrapper script honours $CRAFTY_HOME when set, falling back to
      # $HOME/.local/share/crafty-controller for manual invocations.
      environment.CRAFTY_HOME = cfg.dataDir;
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        ExecStart = lib.getExe crafty-pkg;
        Restart = "on-failure";
        RestartSec = "10s";
        Type = "simple";
        StandardInput = "null";
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ 8443 ];
  };
}
