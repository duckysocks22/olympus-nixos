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
      self.nixosModules.adguard-home

      # (Services): Web
      self.nixosModules.homepage

      # (Services): Files
      self.nixosModules.copyparty
      self.nixosModules.samba

      # (Services): Media
      self.nixosModules.jellyfin
      self.nixosModules.navidrome
      self.nixosModules.freshrss
      self.nixosModules.audiobookshelf
      self.nixosModules.qbittorrent
      self.nixosModules.immich

      # (Services): Automation
      self.nixosModules.home-assistant

      # (Services): Game Servers
      self.nixosModules.game-servers

      # (Services): Finance
      self.nixosModules.actual-budget

      # (Services): Compute
      self.nixosModules.buildHost

      # (Services): Tools
      self.nixosModules.mollysocket
      self.nixosModules.ntfy
      self.nixosModules.sso
      self.nixosModules.atuinServer
      self.nixosModules.futo-notes-server
      self.nixosModules.atticd

      # Host-specific configuration
      ({ lib, ... }: {
        networking.hostName = "nyx-nixos";

        systemd.sleep.settings.Sleep = lib.mkForce {
          AllowSuspend = false;
          AllowHibernation = false;
          AllowHybridSleep = false;
          AllowSuspendThenHibernation = false;
        };

        system.stateVersion = "26.05";
      })
    ];
  };
}
