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
      self.nixosModules.mouseModifiers
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
      };
      security.rtkit.enable = true;
      systemd.sleep.settings.Sleep = {
        HibernateDelaySec = "2h";
      };
      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "26.05";

      nix.settings.trusted-users = [
        "root"
        "foxtrot"
      ];

      # protectKernelImage breaks Jovian/SteamOS-style boot on this host
      security.protectKernelImage = false;

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
                      "/root" = {
                        mountOptions = [
                          "compress=zstd"
                          "subvol=root"
                          "noatime"
                        ];
                        mountpoint = "/";
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
