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
        device = "320c3fee-0b6e-41f3-a82c-9116cc5edc9c";
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
        device = "b50f0f20-8153-49ec-b2e3-b2e75cc68900";
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
	device = "3faa4ce5-f47a-490d-83a0-972fd54ef571";
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
	device = "680b8967-2d52-4e8b-90fc-2e17c91c5624";
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
