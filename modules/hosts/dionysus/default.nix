{
  inputs,
  self,
  lib,
  ...
}:
{
  flake.nixosConfigurations.dionysus-nixos = inputs.nixpkgs-unstable.lib.nixosSystem {
    specialArgs = {
      inherit inputs;
      pkgs-unstable = import inputs.nixpkgs-unstable {
        localSystem = "x86_64-linux";
        config.allowUnfree = true;
      };
    };

    modules = [
      # Base System
      self.nixosModules.dionysusHardware
      self.nixosModules.dionysusDisko
      self.nixosModules.system
      self.nixosModules.preservation
      self.nixosModules.deckSops
      self.nixosModules.buildClient
      self.nixosModules.limine
      self.nixosModules.functions

      # Network
      self.nixosModules.defaultNetwork
      self.nixosModules.netbirdClient
      self.nixosModules.localSamba

      # Users
      self.nixosModules.deck

      # Interface
      self.nixosModules.jovian
      self.nixosModules.fonts
      self.nixosModules.portals

      # Devices
      self.nixosModules.bluetooth
      self.nixosModules.power
      self.nixosModules.amdCPU
      self.nixosModules.amdGPU

      # Software
      self.nixosModules.localsend
      self.nixosModules.appimage-run

      # Host-specific configuration
      ({ lib, ... }: {
        networking.hostName = "dionysus-nixos";

        boot.kernelParams = [
          "pcie_aspm.policy=powersave"
        ];

        boot.kernel.sysctl = {
          "kernel.nmi_watchdog" = 0;
          "vm.dirty_writeback_centisecs" = 1500;
        };

        system.stateVersion = "26.05";
      })
    ];
  };
}
