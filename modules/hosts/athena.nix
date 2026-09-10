{ inputs, self, ... }: {
  flake.nixosConfigurations.athena-nixos = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs;
      pkgs-unstable = import inputs.nixpkgs-unstable {
        localSystem = "x86_64-linux";
        config.allowUnfree = true;
      };
    };
    modules = [
      self.nixosModules.athena
      self.nixosModules.athenaHardware
      self.nixosModules.athenaDisko
      self.nixosModules.functions
      self.nixosModules.preservation
      self.nixosModules.systemHarden
      self.nixosModules.dms-greeter
      self.nixosModules.system
      self.nixosModules.foxtrot
      self.nixosModules.common
      self.nixosModules.defaultNetwork
      self.nixosModules.defaultSops
      self.nixosModules.virtualisation
      self.nixosModules.localPrinting
      self.nixosModules.localSamba
    ];
  };

  flake.nixosModules.athena =
    {
      config,
      pkgs,
      inputs,
      ...
    }:
    {
      environment.systemPackages =
        (with pkgs; [
          git
          wget
          vim
        ])
        ++ [
          self.packages.${pkgs.stdenv.hostPlatform.system}.greenlight
        ];
      networking.hostName = "athena-nixos";
      time.timeZone = "America/New_York";
      services = {
        xserver.xkb = {
          layout = "us";
          variant = "";
        };
        pulseaudio.enable = false;
        pipewire = {
          enable = true;
          alsa = {
            enable = true;
            support32Bit = true;
          };
        };
        libinput.enable = true;
        logind.settings.Login = {
          HandleLidSwitch = "suspend-then-hibernate";
          HandleLidSwitchExternalPower = "suspend-then-hibernate";
        };
      };
      security.rtkit.enable = true;
      systemd.sleep.settings.Sleep = {
        HibernateDelaySec = "2h";
      };
      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "26.05";

      virtualisation.vmVariantWithDisko = {
        virtualisation.qemu.options = [
          "-vga none"
          "-device virtio-gpu-gl-pci"
          "-display gtk,gl=on"
        ];
        boot.initrd.availableKernelModules = [ "virtio_gpu" ];
        boot.initrd.secrets."/tmp/luks-vm.key" = builtins.toFile "luks-vm.key" "disko";
        boot.initrd.luks.devices."crypted".keyFile = "/tmp/luks-vm.key";
        users.users.root.initialPassword = "root";
      };
    };

  flake.nixosModules.athenaDisko = { inputs, lib, ... }: {
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
          device = "/dev/disk/by-id/nvme-CT500P1SSD8_2012E296277B";
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
        ssd2 = {
          device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S76ENL0XB13704D";
          type = "disk";
          imageSize = "40G";
          content = {
            type = "gpt";
            partitions = {
              ssd2linux = {
                size = "100%";
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
      };
    };
    boot.initrd.systemd.enable = lib.mkForce true;
    fileSystems."/nix".neededForBoot = true;
    fileSystems."/persistent".neededForBoot = true;
  };

  flake.nixosModules.athenaHardware =
    {
      config,
      lib,
      pkgs,
      modulesPath,
      ...
    }:
    {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
