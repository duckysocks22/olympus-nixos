{ config, pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
      libva-utils
    ];
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.bleeding_edge;
    modesetting.enable = true;
  };
}
