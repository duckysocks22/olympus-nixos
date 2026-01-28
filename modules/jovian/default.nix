{ config, lib, pkgs, inputs, ...}:
{
imports = [ inputs.jovian.nixosModules.jovian ];
  jovian = {
    steam = {
      enable = true;
      autoStart = true;
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
    hardware = {
      has.amd.gpu = true;
    };
  };
}
