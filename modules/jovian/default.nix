{ config, lib, pkgs, inputs, ...}:
{
imports = [ inputs.jovian.nixosModules.jovian ];
  jovian = {
    steam = {
      enable = true;
      autoStart = true;
      user = "deck";
      desktopSession = "gnome";
      updater.splash = "jovian";
    };
    devices = {
      steamdeck = {
        enable = true;
      };
    };
    steamos = {
      useSteamOSConfig = true;
      enableBluetoothConfig = true;
      enableEarlyOOM = true;
      enableZram = true;
      enableAutoMountUdevRules = false;
    };
    decky-loader = {
      enable = true;
      extraPackages = [ ];
      };
    };

  environment.systemPackages = [
    pkgs.decky-loader
  ];

  systemd.services.steam-cef-debug = lib.mkIf config.jovian.decky-loader.enable {
    description = "Create Steam CEF debugging file";
    serviceConfig = {
      Type = "oneshot";
      User = config.jovian.steam.user;
      ExecStart = "/bin/sh -c 'mkdir -p ~/.steam/steam && [ ! -f ~/.steam/steam/.cef-enable-remote-debugging ] && touch ~/.steam/steam/.cef-enable-remote-debugging || true'";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
