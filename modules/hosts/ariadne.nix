{ inputs, self, ... }: {
  flake.nixosConfigurations.ariadne-nixos = inputs.nixpkgs-unstable.lib.nixosSystem {
    specialArgs = {
      inputs = inputs // {
        nixpkgs = inputs.nixpkgs-unstable;
      };
    };
    modules = [
      self.nixosModules.ariadne
      self.nixosModules.ariadneHardware
      self.nixosModules.ariadneDisko
      self.nixosModules.functions
      self.nixosModules.system
      self.nixosModules.common
      self.nixosModules.systemHarden
      self.nixosModules.defaultNetwork
      self.nixosModules.deck
      self.nixosModules.deckSops
      self.nixosModules.jovian
      self.nixosModules.buildClient
      self.nixosModules.wireguardPeer
    ];
  };

  flake.nixosModules.ariadne =
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
      networking.hostName = "ariadne-nixos";
      networking.networkmanager.enable = true;
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
      powerManagement = {
        enable = true;
        powerDownCommands = ''
          # Clear SteamOS deep-sleep inhibit (InhibitDs) right before suspend,
          # so amd_pmc can reach its deepest s2idle state and won't insta-wake.
          if command -v busctl >/dev/null 2>&1; then
            busctl call com.steampowered.SteamOSManager1 \
              /com/steampowered/SteamOSManager1 \
              org.freedesktop.DBus.Properties Set \
              ssb "com.steampowered.SteamOSManager1.RootManager" "InhibitDs" b false \
              || true
          fi
        '';
        resumeCommands = ''
          # Restore deep-sleep inhibit after resume, matching SteamOS' own default.
          if command -v busctl >/dev/null 2>&1; then
            busctl call com.steampowered.SteamOSManager1 \
              /com/steampowered/SteamOSManager1 \
              org.freedesktop.DBus.Properties Set \
              ssb "com.steampowered.SteamOSManager1.RootManager" "InhibitDs" b true \
              || true
          fi
        '';
      };
      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "26.05";

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

  flake.nixosModules.ariadneDisko = { inputs, lib, ... }: {
    imports = [ inputs.disko.nixosModules.disko ];
    disko.devices = {
      disk = {
        main = {
          device = "/dev/disk/by-id/nvme-Micron_2500_MTFDKBK2T0QGN_253953313CCE";
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
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
    boot.initrd.systemd.enable = lib.mkForce true;
    fileSystems."/nix".neededForBoot = true;
  };

  flake.nixosModules.ariadneHardware =
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
