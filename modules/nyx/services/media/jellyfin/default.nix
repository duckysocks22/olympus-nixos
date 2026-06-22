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
    ./extra.nix
  ];

  services.jellyfin = {
    enable = true;
    package = pkgs-unstable.jellyfin;
    openFirewall = true;
    dataDir = "/media/hdd1/media/jellyfin/media";
    configDir = "/media/hdd1/media/jellyfin/config";
    cacheDir = "/media/hdd1/media/jellyfin/cache";
    logDir = "/media/hdd1/media/jellyfin/logs";
    user = "server";
    forceEncodingConfig = true;
    transcoding = {
      enableHardwareEncoding = true;
      enableToneMapping = true;
      deleteSegments = true;
      # Enable NVDEC hardware decoding.
      # Without this, HEVC is software-decoded on CPU and then uploaded to CUDA
      # for tonemap_cuda, which can lose HDR10 frame side-data on the upload and
      # causes seek-based transcodes to produce black video on some clients.
      # With NVDEC, frames stay in CUDA memory end-to-end and HDR metadata is
      # preserved correctly through the full GPU pipeline.
      hardwareDecodingCodecs = {
        h264 = true;
        hevc = true;
        hevc10bit = true; # required for HDR / 10-bit HEVC (e.g. UHD remuxes)
      };
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

  users.users.jellyfin = {
    isSystemUser = true;
    group = "jellyfin";
  };

  users.groups.jellyfin = {};
}
