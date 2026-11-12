{
  inputs,
  self,
  lib,
  ...
}:
{
  flake.nixosConfigurations.ariadne-nixos = inputs.nixpkgs-unstable.lib.nixosSystem {
    specialArgs = {
      inherit inputs;
      pkgs-unstable = import inputs.nixpkgs-unstable {
        localSystem = "x86_64-linux";
        config.allowUnfree = true;
      };
    };

    modules = [
      # Base System
      self.nixosModules.ariadneHardware
      self.nixosModules.ariadneDisko
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
        networking.hostName = "ariadne-nixos";

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

        system.stateVersion = "26.05";
      })
    ];
  };
}
