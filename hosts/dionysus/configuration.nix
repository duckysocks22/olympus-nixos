# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs-unstable, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/dionysus/jovian.nix
      ../../modules/global/users/foxtrot.nix
      ../../modules/global/system.nix
      ../../modules/global/nix/default.nix
    ];

  networking.hostName = "athena-nixos"; # Define your hostname.
  networking.wireless.iwd.enable = true;

  time.timeZone = "America/New_York";

  services.desktopManager.plasma6.enable = true;
  services.desktopManager.plasma-login-manager.enable = true;
  services.xserver = {
    enable = true;
    xkb.layout = "us";
  };

  services.displayManager.defaultSession = "plasma";
  services.pulseaudio.enable = true;
  services.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  nixpkgs.config.allowUnfree = true;

  environment.plasma6.excludePackages = with pkgs-unstable.kdePackages; [
    plasma-browser-integration
    elisa
  ];

  system.stateVersion = "unstable";
}
