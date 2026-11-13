{ inputs, ... }:
{
  flake.nixosModules.aetherDisko =
    {
      inputs,
      lib,
      ...
    }:
    {
      imports = [ inputs.disko.nixosModules.disko ];

      disko.devices = {
        disk = {
          main = {
            device = "/dev/vda";
            type = "disk";
            imageSize = "35G";
            content = {
              type = "gpt";
              partitions = {
                boot = {
                  size = "1M";
                  type = "EF02";
                  priority = 1;
                };
                ESP = {
                  name = "ESP";
                  size = "1G";
                  type = "EF00";

                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                  };
                };
                swap = {
                  size = "2G";
                  content = {
                    type = "swap";
                    resumeDevice = true;
                  };
                };
                root = {
                  size = "100%";
                  content = {
                    type = "btrfs";
                    extraArgs = [ "-f" ];
                    subvolumes = {
                      "/root" = {
                        mountOptions = [
                          "compress=zstd"
                          "subvol=root"
                          "noatime"
                        ];
                        mountpoint = "/";
                      };
                      "/home" = {
                        mountOptions = [
                          "compress=zstd"
                          "subvol=home"
                          "noatime"
                        ];
                        mountpoint = "/home";
                      };
                      "/nix" = {
                        mountOptions = [
                          "compress=zstd"
                          "subvol=nix"
                          "noatime"
                        ];
                        mountpoint = "/nix";
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };

      fileSystems."/nix".neededForBoot = true;
    };
}
