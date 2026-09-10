{ inputs, self, ... }: {
  flake.nixosConfigurations.ariadne-nixos = inputs.nixpkgs-unstable.lib.nixosSystem {
    specialArgs = {
      inputs = inputs // { nixpkgs = inputs.nixpkgs-unstable; };
    };
    modules = [
      self.nixosModules.ariadne
      self.nixosModules.ariadneHardware
      self.nixosModules.ariadneDisko
      self.nixosModules.functions
      self.nixosModules.system
      self.nixosModules.common
      self.nixosModules.systemHarden
      #self.nixosModules.defaultNetwork
      self.nixosModules.deck
      #self.nixosModules.deckSops
      self.nixosModules.jovian
    ];
  };

  flake.nixosModules.ariadne = { config, pkgs, inputs, ... }: {
    environment.systemPackages = (with pkgs; [ git wget vim]) ++ [
      self.packages.${pkgs.system}.greenlight
    ];
    networking.hostName = "ariadne-nixos";
    time.timeZone = "America/New_York";
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

  flake.nixosModules.ariadneDisko = { inputs, lib, ... }: {
    imports = [ inputs.disko.nixosModules.disko ];
    disko.devices = {
      disk = {
        main = {
          device = "/dev/disk/by-id/nvme-Micron_2500_MTFDKBK2T0QGN_253953313CCE";
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

  flake.nixosModules.ariadneHardware = { config, lib, pkgs, modulesPath, ... }: {
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
