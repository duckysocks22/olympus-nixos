{ config, lib, pkgs-unstable, inputs, ...}:
{
imports = [ inputs.jovian.nixosModules.jovian ];
  jovian = {
    steam = {
      enable = true;
      autoStart = true;
      user = "deck";
      desktopSession = "plasma";
    };
    devices = {
      steamdeck = {
        enable = true;
        enableControllerUdevRules = true;
      };
    };
    decky-loader = {
      enable = true;
    };
  };
}
