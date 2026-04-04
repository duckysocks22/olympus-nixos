{ inputs, ...}:
{
  flake.nixosModules.athena-hardware = { config, lib, pkgs, modulesPath, ... }: {
    imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
      boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];
    
      fileSystems."/" =
        { device = "/dev/disk/by-uuid/28b23cad-abc9-4986-9e0a-044e259ec6a8";
          fsType = "btrfs";
          options = [ "subvol=@root" ];
        };
    
      fileSystems."/home" =
        { device = "/dev/disk/by-uuid/28b23cad-abc9-4986-9e0a-044e259ec6a8";
          fsType = "btrfs";
          options = [ "subvol=@home" ];
        };
    
      fileSystems."/boot" =
        { device = "/dev/disk/by-uuid/9125-D8B9";
          fsType = "vfat";
          options = [ "fmask=0077" "dmask=0077" ];
        };
    
      swapDevices =
        [ { device = "/dev/disk/by-uuid/861f99a4-62f5-4afd-acfa-3fcce11ee87c"; }
        ];
    
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
