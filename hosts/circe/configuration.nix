# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      #../../modules/greeter/ly.nix
      ../../modules/global/greeter/cosmic-greeter.nix
      ../../modules/global/portals.nix
      ../../modules/global/system.nix
      ../../modules/global/users/foxtrot.nix
      ../../modules/global/common.nix
      ../../modules/global/network/default-network.nix
      ../../modules/global/services/thelounge.nix
      ../../modules/global/nix/default.nix
      ../../modules/global/sops.nix
      ../../modules/global/virtualisation.nix
      ../../modules/global/local-printing.nix
    ];

  home-manager.users.foxtrot = import ../../home/users/foxtrot/core.nix;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-ecfee8fe-d5b0-4792-bef7-6610b5bfbc95".device = "/dev/disk/by-uuid/ecfee8fe-d5b0-4792-bef7-6610b5bfbc95";
  boot.initrd.luks.devices."luks-ecfee8fe-d5b0-4792-bef7-6610b5bfbc95".bypassWorkqueues = true;

  boot.resumeDevice = "/dev/dm-1";
  systemd.sleep.extraConfig = ''
    HibernationDelaySec=30m
  '';

  # Use latest kernel.
  #boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "circe-nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.wireless.iwd.enable = true;
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

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
   services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.foxtrot = {
    isNormalUser = true;
    description = "Socks";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [

    ];
  };

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

 

  system.stateVersion = "25.11";

}
