{ pkgs, ...}:
{
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;

  environment.systemPackages = with pkgs; [
    nvidia-vaapi-driver
  ];
}
