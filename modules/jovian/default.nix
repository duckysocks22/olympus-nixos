{ config, lib, pkgs, inputs, ...}:
{
imports = [ inputs.jovian.nixosModules.jovian ];
  jovian = {
    steam = {
      enable = true;
      autoStart = true;
      user = "deck";
      desktopSession = "plasma";
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
      updater.splash = "jovian";
      enableAutoMountUdevRules = true;
    };
    decky-loader = {
      enable = true;
      user = "decky";
      };
    };
  };
}
