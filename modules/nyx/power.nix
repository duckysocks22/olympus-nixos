{ lib, ... }:
{
  powerManagement = {
    cpuFreqGovernor = "ondemand";
    cpufreq = {
      max = 2800000;
      min = 1000000;
    };
    powertop.enable = true;
  };

  boot.kernelParams = lib.mkForce [ "amd_pstate=disable" ];
}
