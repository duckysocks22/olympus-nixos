{ inputs, ... }:
{
  flake.nixosModules.nyxHardware =
    {
      config,
      lib,
      pkgs,
      modulesPath,
      ...
    }:
    {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

      boot = {
        initrd.availableKernelModules = [
          "nvme"
          "xhci_pci"
          "ahci"
          "usbhid"
          "sd_mod"
        ];

        initrd.kernelModules = [ ];
        kernelModules = [ "kvm-amd" ];
        extraModulePackages = [ ];
      };

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/e52fc7d2-ca39-4502-8f55-2a9522eae878";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/8DE9-AB27";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      fileSystems."/media/hdd1" = {
        device = "/dev/disk/by-uuid/f269dd7a-3b90-4927-99ae-201fcfdda001";
        fsType = "btrfs";
      };

      swapDevices = [
        { device = "/dev/disk/by-uuid/68518eb1-5d79-48e6-9595-eff62acd6a5f"; }
      ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
