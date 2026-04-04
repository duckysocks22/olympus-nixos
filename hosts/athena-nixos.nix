{ inputs, self, ... }: {

  flake.nixosConfigurations.athena-nixos = inputs.nixpkgs.lib.nixosSystem { 
    modules = [
      self.nixosModules.athena-module
      self.nixosModules.athena-hardware
      self.nixosModules.sound
      self.nixosModules.common
      self.nixosModules.nix-settings
      self.nixosModules.portals
      self.nixosModules.sops
      self.nixosModules.system
      self.nixosModules.virtualisation
      self.nixosModules.foxtrot
      self.nixosModules.default-network
      self.nixosModules.cosmic-greeter
    ];

    specialArgs = {
      inherit inputs;
      flake-parts-lib = inputs.flake-parts.lib;
    };
  };

  flake.nixosModules.athena-module = { pkgs, ... }: {
    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = "athena-nixos"; # Define your hostname.
  
    # Set your time zone.
    time.timeZone = "America/New_York";
  
    security.rtkit.enable = true;
  
    environment.variables.EDITOR = "nvim";
  
    services.openssh.enable = true;
  
    system.stateVersion = "25.11";

  };
}
