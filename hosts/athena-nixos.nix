{ inputs, self, ... }: {

  flake.nixosConfigurations.athena-nixos = inputs.nixpkgs.lib.nixosSystem { 
    self.nixosModules.athena-module
    self.nixosModules.sound
  };

  flake.nixosModules.athena-module = { pkgs, ... }: {
    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  
    services.logind.settings.Login = {
      HandlePowerKey = "ignore";
      HandleRebootKey = "ignore";
      HandleHibernateKey = "ignore";
    };
  
  
    networking.hostName = "athena-nixos"; # Define your hostname.
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  
    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  
    # Enable network manager applet
    programs.nm-applet.enable = true;
  
    networking.wireless.iwd.enable = true;
  
  
    # Set your time zone.
    time.timeZone = "America/New_York";
  
    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };
  
  
    # Please remove and make own module,,,,, -------------------------------------------------------------
  
    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;
  
      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };
  
    # Enable touchpad support (enabled default in most desktopManager).
    # services.xserver.libinput.enable = true;
  
  
    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;
  
    # List packages installed in system profile. To search, run:
    # $ nix search wget
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    environment.systemPackages = with pkgs; [
      git  
      #neovim
      wget
    ];
  
    environment.variables.EDITOR = "nvim";
  
    services.openssh.enable = true;
  
    # -------------------------------------------------------------------------------------------------
  
    system.stateVersion = "25.11";

  };
}
