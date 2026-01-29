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
      enableAutoMountUdevRules = true;
    };
    decky-loader = {
      enable = true;
      user = "decky";
      };
    };
}
