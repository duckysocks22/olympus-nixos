{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/nvme1n1";
	type = "disk";
	content = {
	  type = "gpt";
	  partitions = {
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
                    "/rootfs" = {
                      mountpoint = "/";
                    };
                    "/home" = {
                      mountOptions = [ "compress=zstd" ];
                      mountpoint = "/home";
                    };
                    "/nix" = {
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                      mountpoint = "/nix";
                    };
                    "/swap" = {
                      mountpoint = "/.swapvol";
                      swap = {
                        swapfile.size = "8192M";
                        swapfile2.size = "8192M";
                        swapfile2.path = "rel-path";
                      };
                    };
                    "/media" = { 
                      mountpoint = "/media";
                    };
                  };

                  mountpoint = "/partition-root";
                  swap = {
                    swapfile = {
                      size = "8192M";
                    };
                    swapfile2 = {
                      size = "8192M";
                    };
                  };
                };
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
	device = "/dev/sda1";
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
	device = "/dev/sdb1";
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
}
