{ inputs, self, ... }:
{
  flake.nixosModules.circeDisko =
    {
      inputs,
      lib,
      ...
    }:
    {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.self.nixosModules.diskoVM
      ];

      disko.devices = {
        disk = {
          main = {
            device = "/dev/disk/by-id/nvme-SAMSUNG_MZVL81T0HFLB-00BH1_S7T8NF0Y375930";
            type = "disk";
            imageSize = "40G";
            content = {
              type = "gpt";
              partitions = {
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
                  size = "16G";
                  content = {
                    type = "luks";
                    name = "crypted-swap";
                    settings = {
                      allowDiscards = true;
                    };
                    content = {
                      type = "swap";
                      resumeDevice = true;
                    };
                  };
                };
                luks = {
                  size = "100%";
                  content = {
                    type = "luks";
                    name = "crypted";
                    settings = {
                      allowDiscards = true;
                    };
                    content = {
                      type = "btrfs";
                      extraArgs = [ "-f" ];
                      subvolumes = {
                        "/persistent" = {
                          mountOptions = [
                            "subvol=persistent"
                            "noatime"
                          ];
                          mountpoint = "/persistent";
                        };
                        "/nix" = {
                          mountOptions = [
                            "compress=zstd"
                            "subvol=nix"
                            "noatime"
                          ];
                          mountpoint = "/nix";
                        };
                        "/root" = {
                          mountOptions = [
                            "compress=zstd"
                            "subvol=root"
                            "noatime"
                          ];
                          mountpoint = "/";
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
}
