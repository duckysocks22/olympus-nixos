{ lib, pkgs-unstable, ... }:
{
  jovian = {
    steam = {
      enable = true;
      user = "foxtrot";
      autoStart = true;
      desktopSession = "plasma";
      updater = {
        splash = "jovian";
      };
    };
    decky-loader = {
      enable = true;
    };
    devices = {
      steamdeck = {
        autoUpdate = true;
        enable = true;
        enableVendorDrivers = true;
      };
    };
    hardware = {
      has.amd.gpu = true;
    };
  };
  boot.kernelPackages = lib.mkForce pkgs-unstable.linuxPackages_zen;
}
