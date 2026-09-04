{ inputs, self, ... }: {
  flake.nixosConfigurations.circe = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.circe
      self.nixosModules.circeHardware
      self.nixosModules.circeDisko
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

  flake.nixosModules.circe = { config, pkgs, inputs, ... }: {

    environment.systemPackages = (with pkgs; [ git wget vim ]) ++ (with self.packages.${pkgs.system}; [
      dwproton
      greenlight
    ]);
    networking.hostName = "circe-nixos";
    time.timeZone = "America/New_York";
    services = {
      xserver.xkb = {
        layout = "us";
        variant = "";
      };
      pulseaudio.enable = false;
      pipewire = {
        enable = true;
        alsa = { enable = true; support32Bit = true; };
        pulse.enable = true;
      };
      libinput.enable = true;
      logind.settings.Login = { HandleLidSwitch = "suspend-then-hibernate"; HandleLidSwitchExternalPower = "suspend-then-hibernate"; };
    };
    security.rtkit.enable = true;
    systemd.sleep.settings.Sleep = {
      HibernateDelaySec = "2h";
    };
    nixpkgs.config.allowUnfree = true;
    system.stateVersion = "26.05";
  };

  flake.nixosModules.circeDisko = { lib, ... }: {
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
          device = "/dev/disk/by-id/nvme-SAMSUNG_MZVL81T0HFLB-00BH1_S7T8NF0Y375930";
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
      };
    };

    boot.initrd.systemd.enable = lib.mkForce true;
    fileSystems."/nix".neededForBoot = true;
    fileSystems."/persistent".neededForBoot = true;
  };

  flake.nixosModules.circeHardware = { config, lib, pkgs, modulesPath, ... }: {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

    boot = {
      kernelModules = [ "kvm-amd" ];
      extraModulePackages = [ ];
      initrd = {
        kernelModules = [ ];
        availableKernelModules = [
          "nvme"
          "xhci_pci"
          "thunderbolt"
        ];
      };
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.,hardware.enableRedistributableFirmware;
  };
}
