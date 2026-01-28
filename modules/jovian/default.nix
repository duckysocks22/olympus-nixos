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
        enableControllerUdevRules = true;
        enableDefaultStage1Modules = true;
        enableKernelPatches = true;
        enablePerfControlUdevRules = false;
        enableSoundSupport = true;
        enableVendorDrivers = true;
      };
    };
    steamos = {
      enableBluetoothConfig = true;
      enableEarlyOOM = true;
      enableSysctlConfig = true;
      enableZram = true;
    };
    decky-loader = {
      enable = true;
    };
  };
}
