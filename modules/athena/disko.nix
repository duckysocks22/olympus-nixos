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
        device = "/dev/disk/by-id/nvme-CT500P1SSD8_2012E296277B";
	type = "disk";
	content = {
	  type = "gpt";
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
	      size = "358400M";
                content = {
                type = "luks";
                name = "crypted";
                settings = {
                  allowDiscards = true;
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
      ssd2 = {
        device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S76ENL0XB13704D";
	type = "disk";
	content = {
	  type = "gpt";
	  partitions = {
	    ssd2linux = {
	      size = "1500G";
	      content = {
		type = "filesystem";
		format = "xfs";
		mountpoint = "/media/ssd2linux";
		mountOptions = [ "noatime" ];
	      };
	    };
	  };
	};
      };
      extra = {
	device = "/dev/disk/by-id/ata-ST2000DM008-2FR102_ZFL287RG";
	type = "disk";
	content = {
	  type = "gpt";
	  partitions = {
	    extraLinux = {
	      size = "1500G";
	      content = {
		type = "filesystem";
		format = "xfs";
		mountpoint = "/media/extraLinux";
		mountOptions = [ "noatime" ];
	      };
	    };
	  };
	};
      };
      plus = {
	device = "/dev/disk/by-id/ata-WDC_WD10EZEX-60WN4A0_WD-WCC6Y2UVT50Y";
	type = "disk";
	content = {
	  type = "gpt";
	  partitions = {
	    plus = {
	      size = "100%";
	      content = {
		type = "filesystem";
		format = "xfs";
		mountpoint = "/media/plus";
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
