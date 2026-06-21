{ lib, ...}:
{
  disko.devices = {

    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "size=25%"
          "mode=755"
        ];
      };
    };

    disk = {
      main = {
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZVL81T0HFLB-00BH1_S7T8NF0Y375930";
	type = "disk";
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
                  };
                };
              };
            };
	  };
        };
      };
    };
  };
  boot.initrd.systemd.enable = lib.mkForce true;
  fileSystems."/nix".neededForBoot = true;
  fileSystems."/persistent".neededForBoot = true;
}
