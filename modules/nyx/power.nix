{ lib, ... }:
{
  powerManagement = {
    cpuFreqGovernor = "performance";
    cpufreq = {
      max = 4500000;
      min = 100000;
    };
  };

  boot.kernelParams = lib.mkForce [ "amd_pstate=active" "crashkernel=256M" ];
}
