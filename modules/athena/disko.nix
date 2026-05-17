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
        device = "/dev/nvme1n1";
	type = "disk";
	content = {
	  type = "gpt";
	  partitions = {
            boot = {
              name = "boot";
              size = "1M";
              type = "EF02";
            };
	    ESP = {
	      end = "500M";
	      type = "EF00";
	      content = {
	        type = "filesystem";
	        format = "vfat";
	        mountpoint = "/boot";
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
            swap = {
              size = "8G";

              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
	  };
        };
      };
      ssd2 = {
        device = "/dev/nvme0n1";
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
	device = "/dev/sda";
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
	device = "/dev/sdb";
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
}
