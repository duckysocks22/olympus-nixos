{ pkgs-unstable, pkgs, inputs, ... }:
{

  environment.systemPackages = with pkgs; [
    jellyfin-web
    jellyfin-ffmpeg
  ];

  disabledModules = [
    "services/misc/jellyfin.nix"
  ];

  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/jellyfin.nix"
  ];

  services.jellyfin = {
    enable = true;
    package = pkgs-unstable.jellyfin;
    openFirewall = true;
    dataDir = "/media/hdd1/media/jellyfin/media";
    configDir = "/media/hdd1/media/jellyfin/config";
    user = "server";
    forceEncodingConfig = true;
    transcoding = {
      enableHardwareEncoding = true;
      enableToneMapping = true;
      deleteSegments = true;
    };
    hardwareAcceleration = {
      enable = true;
      type = "nvenc";
      device = "/dev/dri/renderD128";
    };
  };

  systemd.services.jellyfin.serviceConfig = {
  DeviceAllow = [
    "/dev/nvidiactl rw"
    "/dev/nvidia0 rw"
    "/dev/nvidia-uvm rw"
    "/dev/nvidia-uvm-tools rw"
  ];
  PrivateDevices = false;
};
}
