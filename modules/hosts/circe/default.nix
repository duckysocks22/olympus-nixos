{
  inputs,
  self,
  lib,
  ...
}:
{
  flake.nixosConfigurations.circe-nixos = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs;
      pkgs-unstable = import inputs.nixpkgs-unstable {
        localSystem = "x86_64-linux";
        config.allowUnfree = true;
      };
    };

    modules = [
      # Base System
      self.nixosModules.circeHardware
      self.nixosModules.circeDisko
      self.nixosModules.system
      self.nixosModules.systemHarden
      self.nixosModules.preservation
      self.nixosModules.defaultSops
      self.nixosModules.buildClient
      self.nixosModules.limine
      self.nixosModules.plymouth
      self.nixosModules.functions

      # Keyring
      self.nixosModules.gnome-keyring

      # Network
      self.nixosModules.defaultNetwork
      self.nixosModules.mullvad
      self.nixosModules.dnscrypt-proxy
      self.nixosModules.i2pd
      self.nixosModules.netbirdClient
      self.nixosModules.localSamba

      # Users
      self.nixosModules.foxtrot

      # Interface
      self.nixosModules.portals
      self.nixosModules.fonts
      self.nixosModules.dms-greeter

      # Devices
      self.nixosModules.bluetooth
      self.nixosModules.power
      self.nixosModules.amdCPU
      self.nixosModules.amdGPU
      self.nixosModules.finalMouse
      self.nixosModules.mouseModifiers
      self.nixosModules.printing
      self.nixosModules.olympus-canon

      # Software
      self.nixosModules.steam
      self.nixosModules.qemu
      self.nixosModules.vmTest
      self.nixosModules.gpu-screen-recorder
      self.nixosModules.localsend
      self.nixosModules.appimage-run

      # Host-specific configuration
      ({ lib, ... }: {
        networking.hostName = "circe-nixos";

        # Fix issues with resuming from hibernation
        boot.kernelPatches = [
          {
            name = "hibernate-lz4";
            patch = null;
            structuredExtraConfig = {
              HIBERNATION_COMP_LZ4 = lib.kernel.yes;
              HIBERNATION_DEF_COMP = lib.kernel.freeform "lz4";
            };
          }
        ];

        boot.kernelParams = [
          "pcie_aspm.policy=powersave"
        ];

        # Keep bluetooth radio from waking device when earbuds power on
        services.udev.extraRules = ''
          ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", ATTR{idProduct}=="223c", ATTR{power/wakeup}="disabled"
        '';

        services.tuned = {
          profiles.circe-balanced-battery = {
            main.include = "balanced-battery";

            sysfs = {
              "/sys/class/platform-profile/platform-profile-0/profile" = "low-power";
            };

            sysctl = {
              "kernel.nmi_watchdog" = "0";
              "vm.dirty_writeback_centisecs" = "1500";
            };
          };

          ppdSettings.battery.balanced = "circe-balanced-battery";
        };

        system.stateVersion = "26.05";
      })
    ];
  };
}
