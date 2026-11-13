{
  inputs,
  self,
  lib,
  ...
}:
{
  flake.nixosConfigurations.aether-nixos = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs;
      pkgs-unstable = import inputs.nixpkgs-unstable {
        localSystem = "x86_64-linux";
        config.allowUnfree = true;
      };
    };

    modules = [
      # Base System
      self.nixosModules.aetherHardware
      self.nixosModules.aetherDisko
      self.nixosModules.system
      self.nixosModules.systemHarden
      self.nixosModules.aetherSops
      self.nixosModules.buildClient

      # Network
      self.nixosModules.serverNetwork
      self.nixosModules.relayTunnel

      # Users
      self.nixosModules.server

      # (Services): Network
      self.nixosModules.networkPassthrough
      self.nixosModules.netbirdCoturn
      self.nixosModules.routeVPNMullvad

      # Host-specific configuration
      ({ lib, ... }: {
        networking.hostName = "aether-nixos";

        systemd.sleep.settings.Sleep = lib.mkForce {
          AllowSuspend = false;
          AllowHibernation = false;
          AllowHybridSleep = false;
          AllowSuspendThenHibernation = false;
        };

        boot.initrd.systemd.enable = lib.mkForce true;

        boot.loader.grub = {
          enable = true;
          device = "/dev/vda";
          efiSupport = true;
          efiInstallAsRemovable = true;
        };

        system.stateVersion = "26.05";
      })
    ];
  };
}
