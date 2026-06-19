{ lib, ...}:
{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/nvme-CT500P1SSD8_2012E296277B";
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
                type = "swap";
                resumeDevice = true;
              };
            };
	    luks = {
	      size = "100%";
                content = {
                type = "luks";
                name = "crypted";
                settings = {
                  allowDiscards = true;
                  crypttabExtraOpts = ["tpm2-device=auto"];
                };
                extraFormatArgs = [ "tpm2-device=auto" ];
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
      SD512 = {
        device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S76ENL0XB13704D";
	type = "disk";
	content = {
	  type = "gpt";
	  partitions = {
	    ssd2linux = {
	      size = "100%";
	      content = {
		type = "filesystem";
		format = "xfs";
		mountpoint = "/media/SD512";
		mountOptions = [ "noatime" ];
	      };
	    };
	  };
	};
      };
    };
  };
  boot.initrd.systemd.enable = lib.mkForce true;
  fileSystems."/nix".neededForBoot = true;
}
