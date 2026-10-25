{ inputs, self, ... }: {
  flake.nixosConfigurations.ares-nixos = inputs.nixpkgs-unstable.lib.nixosSystem {
    specialArgs = {
      inputs = inputs // {
        nixpkgs = inputs.nixpkgs-unstable;
      };
    };
    modules = [
      self.nixosModules.ares
      self.nixosModules.aresHardware
      self.nixosModules.aresDisko
      self.nixosModules.functions
      self.nixosModules.system
      self.nixosModules.mouseModifiers
      self.nixosModules.common
      self.nixosModules.systemHarden
      self.nixosModules.preservation
      self.nixosModules.vmTest
      self.nixosModules.defaultNetwork
      self.nixosModules.deck
      self.nixosModules.deckSops
      self.nixosModules.jovian
      self.nixosModules.buildClient
      self.nixosModules.wireguardPeer
    ];
  };

  flake.nixosModules.ares =
    {
      config,
      pkgs,
      inputs,
      lib,
      ...
    }:
    {
      networking.hostName = "ares-nixos";
      time.timeZone = "America/New_York";
      networking.networkmanager.enable = true;
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
        openssh = {
          enable = true;
          openFirewall = true;
          ports = [
            22
          ];
          settings = {
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            PermitRootLogin = "no";
          };
        };
      };
      security.rtkit.enable = true;
      systemd.sleep.settings.Sleep = {
        HibernateDelaySec = "2h";
      };
      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "26.05";

      security.protectKernelImage = false;

      boot = {
        kernelParams = [
          "pcie_aspm.policy=powersave"
        ];
        extraModprobeConfig = ''
          options snd_hda_intel power_save=10
        '';
      };

      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
      '';

      boot.kernel.sysctl = {
        "kernel.nmi_watchdog" = 0;
        "vm.dirty_writeback_centisecs" = 1500;
      };

      virtualisation.vmVariantWithDisko = {
        boot.initrd.availableKernelModules = [ "virtio_gpu" ];
        boot.initrd.secrets."/tmp/luks-vm.key" = builtins.toFile "luks-vm.key" "disko";
        boot.initrd.luks.devices."crypted".keyFile = "/tmp/luks-vm.key";
        users.users.root.initialPassword = "root";
      };

      nix.package = lib.mkForce (
        pkgs.lixPackageSets.lix_2_96.lix.overrideAttrs (prev: {
          mesonFlags = map (
            flag: if lib.hasPrefix "-Dmimalloc=" flag then "-Dmimalloc=disabled" else flag
          ) prev.mesonFlags;
          buildInputs = builtins.filter (input: (input.pname or "") != "mimalloc") prev.buildInputs;
        })
      );
    };

  flake.nixosModules.aresDisko = { inputs, lib, ... }: {
    imports = [ inputs.disko.nixosModules.disko ];
    disko.devices = {
      disk = {
        main = {
          device = "/dev/disk/by-id/nvme-FORESEE_FSB0C512G-B7C0700_QGB1134123824";
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
                  content = {
                    type = "btrfs";
                    extraArgs = [ "-f" ];
                    subvolumes = {
                      "/root" = {
                        mountOptions = [
                          "compress=zstd"
                          "subvol=root"
                          "noatime"
                        ];
                        mountpoint = "/";
                      };
                      "/nix" = {
                        mountOptions = [
                          "compress=zstd"
                          "subvol=nix"
                          "noatime"
                        ];
                        mountpoint = "/nix";
                      };
                      "/home" = {
                        mountOptions = [
                          "compress=zstd"
                          "subvol=home"
                          "noatime"
                        ];
                        mountpoint = "/home";
                      };
                      "/persistent" = {
                        mountOptions = [
                          "subvol=persistent"
                          "noatime"
                        ];
                        mountpoint = "/persistent";
                      };
                    };
                  };
                };
              };
            };
          };
        };
        SD256 = {
          device = "/dev/disk/by-id/mmc-SC256_0xf02b8d85";
          type = "disk";
          imageSize = "40G";
          content = {
            type = "gpt";
            partitions = {
              SD512 = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "xfs";
                  mountpoint = "/media/SD256";
                  mountOptions = [ "noatime" ];
                };
              };
            };
          };
        };
      };
    };
    fileSystems."/nix".neededForBoot = true;
    fileSystems."/persistent".neededForBoot = true;

    boot.initrd.systemd.services.wipe-root = {
      description = "Reset btrfs root subvol for stateless boot";
      wantedBy = [ "initrd-root-device.target" ];
      before = [ "sysroot.mount" ];
      after = [
        "dev-mapper-crypted.device"
        "local-fs-pre.target"
      ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        mount --mkdir -o subvol=/ /dev/mapper/crypted /btrfs_tmp
        if [[ -e /btrfs_tmp/root ]]; then
          mkdir -p /btrfs_tmp/old_roots
          timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%d_%H:%M:%S")
          mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
        fi
        for old_root in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mindepth 1 -mtime +7); do
          btrfs subvolume delete --recursive "$old_root"
        done
        btrfs subvolume create /btrfs_tmp/root
        umount /btrfs_tmp
      '';
    };
  };

  flake.nixosModules.aresHardware =
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
