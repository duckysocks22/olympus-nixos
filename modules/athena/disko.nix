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
	    root = {
	      size = "100%";
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
	        };
	      };

	      mountpoint = "/partition-root";
	      swap = {
	        swapfile = {
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
  };
}
