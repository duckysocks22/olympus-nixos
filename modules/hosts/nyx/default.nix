{
  inputs,
  self,
  lib,
  ...
}:
{
  flake.nixosConfigurations.nyx-nixos = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs;
      pkgs-unstable = import inputs.nixpkgs-unstable {
        localSystem = "x86_64-linux";
        config.allowUnfree = true;
      };
    };

    modules = [
      # Base System
      self.nixosModules.nyxHardware
      self.nixosModules.system
      self.nixosModules.systemHarden
      self.nixosModules.serverSops
      self.nixosModules.limine
      self.nixosModules.functions

      # Network
      self.nixosModules.serverNetwork
      self.nixosModules.mullvad
      self.nixosModules.relayTunnel
      self.nixosModules.nyx-caddy

      # Users
      self.nixosModules.server

      # Interface
      self.nixosModules.fonts

      # Devices
      self.nixosModules.amdCPU
      self.nixosModules.nvidia
      self.nixosModules.printing
      self.nixosModules.olympus-canon

      # Software
      self.nixosModules.appimage-run
      self.nixosModules.syncthing

      # (Services): Networking
      self.nixosModules.netbirdServer

      # (Services): Media
      self.nixosModules.jellyfin
      self.nixosModules.navidrome
      # self.nixosModules.freshrss
      self.nixosModules.audiobookshelf
      self.nixosModules.qbittorrent

      self.nixosModules.automation # MISSING
      self.nixosModules.gameServers # MISSING
      self.nixosModules.files # MISSING
      self.nixosModules.buildHost # MISSING
      self.nixosModules.compute # MISSING
      self.nixosModules.atuinServer # MISSING
      self.nixosModules.atuionAIServer # MISSING
      self.nixosModules.homepage # MISSING
      self.nixosModules.futo-notes-server # MISSING

      # Host-specific configuration
      ({ lib, ... }: {
        networking.hostName = "nyx-nixos";

        system.stateVersion = "26.05";
      })
    ];
  };
}
