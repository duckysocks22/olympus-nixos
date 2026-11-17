{
  inputs,
  self,
  lib,
  ...
}:
{
  flake.nixosConfigurations.athena-nixos = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs;
      pkgs-unstable = import inputs.nixpkgs-unstable {
        localSystem = "x86_64-linux";
        config.allowUnfree = true;
      };
    };

    modules = [
      # Base System
      self.nixosModules.athenaHardware
      self.nixosModules.athenaDisko
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
        networking.hostName = "athena-nixos";

        system.stateVersion = "26.05";
      })
    ];
  };
}
