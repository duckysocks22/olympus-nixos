{ inputs, self, ... }: {
  flake.nixosConfigurations.dionysus-nixos = inputs.nixpkgs-unstable.lib.nixosSystem {
    specialArgs = {
      inputs = inputs // { nixpkgs = inputs.nixpkgs-unstable; };
    };
    modules = [
      self.nixosModules.dionysus
      self.nixosModules.dionysusHardware
      self.nixosModules.dionysusDisko
      self.nixosModules.functions
      self.nixosModules.preservation
      self.nixosModules.system
      self.nixosModules.common
      self.nixosModules.systemHarden
      #self.nixosModules.defaultNetwork
      self.nixosModules.deck
      #self.nixosModules.deckSops
      self.nixosModules.jovian
    ];
  };

  flake.nixosModules.dionysus = { config, pkgs, inputs, ... }: {
    networking.hostName = "dionysus-nixos";
    time.timeZone = "America/New_York";
    networking.networkmanager.enable = true;
    services = {
      xserver.xkb = { layout = "us"; variant = ""; };
      pulseaudio.enable = false;
      pipewire = { 
        enable = true;
        alsa = { enable = true; support32Bit = true; };
      };
      libinput.enable = true;
    };
    security.rtkit.enable = true;
    systemd.sleep.settings.Sleep = {
      HibernateDelaySec = "2h";
    };
    nixpkgs.config.allowUnfree = true;
    system.stateVersion = "26.05";
  };

  flake.nixosModules.dionysusDisko = { inputs, lib, ... }: {
    imports = [ inputs.disko.nixosModules.disko ];
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
          device = "/dev/disk/by-id/nvme-Phison_ESMP512GMB47C3_E13TS_22373M51232552";
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
                    crypttabExtraOpts = [ "tpm2-device=auto" ];
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
          device = "/dev/disk/by-id/mmc-SD512_8x7e015778";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              SD512 = {
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
    fileSystems."/persistent".neededForBoot = true;
  };

  flake.nixosModules.dionysusHardware = { config, lib, pkgs, modulesPath, ... }: {
    imports = [(modulesPath + "/installer/scan/not-detected.nix")];
    boot.initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-amd" ];
    boot.extraModulePackages = [ ];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
