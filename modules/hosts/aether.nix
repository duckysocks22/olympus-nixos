{ inputs, self, ... }: {
  flake.nixosConfigurations.aether-nixos = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs;
      pkgs-unstable = import inputs.nixpkgs-unstable {
        localSystem = "x86_64-linux";
        config.allowUnfree = true;
      };
    };
    modules = [
      self.nixosModules.aether
      self.nixosModules.aetherHardware
      self.nixosModules.aetherDisko
      self.nixosModules.serverNetwork
      self.nixosModules.server
      self.nixosModules.aetherSops
      self.nixosModules.buildClient
    ];
  };

  flake.nixosModules.aether = { config, pkgs, inputs, lib, ... }: {
    users.mutableUsers = false;
    users.users.root.hashedPasswordFile = config.sops.secrets."users/server".path;

    systemd.sleep.settings.Sleep = {
      AllowSuspend = false;
      AllowHiberntion = false;
      AllowHybridSleep = false;
      AllowSuspendThenHibernation = false;
    };

    networking.hostName = "aether-nixos";
    networking.useDHCP = lib.mkForce false;

    services.resolved.enable = false;
    networking.resolvconf.useLocalResolver = true;
    networking.networkmanager.insertNameservers = [ "127.0.0.1" ];

    time.timeZone = "America/New_York";
    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };
    };

    services = {
      xserver.xkb = {
        layout = "us";
        variant = "";
      };
      openssh = {
        enable = true;
        openFirewall = true;
        ports = [ 22 2222 ];
      };
    };

    nixpkgs.config.allowUnfree = true;
    programs.zsh.enable = true;
    environment.systemPackages = with pkgs; [
      vim
      wget
      git
    ];

    system.stateVersion = "26.05";
  };

  flake.nixosModules.aetherDisko = { inputs, lib, ... }: {
    imports = [ inputs.disko.nixosModules.disko ];

    disko.devices = {
      disk = {
        main = {
          device = "/dev/vda";
          type = "disk";
          imageSize = "35G";
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
                size = "2G";
                content = {
                  type = "luks";
                  name = "crypted-swap";
                  settings = {
                    allowDiscards = true;
                  };
                  content = {
                    type = "swap";
                    resumeDevice = true;
                  };
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
                      "/root" = {
                        mountOptions = [
                          "compress=zstd"
                          "subvol=root"
                          "noatime"
                        ];
                        mountpoint = "/";
                      };
                      "/home" = {
                        mountOptions = [
                          "compress=zstd"
                          "subvol=home"
                          "noatime"
                        ];
                        mountpoint = "/home";
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
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    fileSystems."/nix".neededForBoot = true;
  };

  flake.nixosModules.aetherHardware = { config, lib, pkgs, modulesPath, ... }: {
    imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

    boot = {
      initrd = {
        availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
        kernelModules = [ ];
      };
      kernelModules = [ ];
      extraModulePackages = [ ];
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
