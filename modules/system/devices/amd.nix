{ inputs, self, ... }:
{
  flake.nixosModules.amdGPU =
    {
      pkgs,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        mesa.opencl
      ];

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = [ pkgs.mesa.opencl ];
      };

      environment.variables.RUSTICL_ENABLE = "radeonsi";
    };

  flake.nixosModules.amdCPU =
    {
      ...
    }:
    {
      boot.kernelParams = [
        "amd_pstate=active"
        "amd_iommu=on"
      ];
    };
}
