# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/athena/disko.nix
      ../../modules/global/preservation.nix
      ../../modules/global/remote-builder.nix
      ../../modules/global/harden.nix
      #../../modules/greeter/ly.nix
      ../../modules/global/greeter/cosmic-greeter.nix
      ../../modules/global/portals.nix
      ../../modules/global/system.nix
      ../../modules/global/stress.nix
      ../../modules/global/users/foxtrot.nix
      ../../modules/athena/samba-local.nix
      ../../modules/global/common.nix
      ../../modules/global/network/default-network.nix
      ../../modules/global/services/thelounge.nix
      ../../modules/global/nix/default.nix
      ../../modules/global/sops.nix
      ../../modules/global/virtualisation.nix
      ../../modules/global/local-printing.nix
      ../../modules/packages/default.nix
    ];

  #home-manager.users.foxtrot = import ../../home/users/foxtrot/core.nix;

  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "ignore";
    HandleSuspendKey = "ignore";
    HandleSuspendKeyLongPress = "ignore";
    HandleRebootKey = "ignore";
    HandleHibernateKey = "ignore";
  };

  boot.kernelParams = [
    "mem_sleep_default=s2idle"
    "processor.max_cstate=1"
  ];

  networking.hostName = "athena-nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable network manager applet
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
    liquidctl
  ];

  services.udev.packages = [ pkgs.liquidctl ];

  systemd.services.liquidcfg = {
    description = "NZXT Kraken fan/pump curve";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "liquidcfg" ''
        ${pkgs.liquidctl}/bin/liquidctl --match kraken initialize
        ${pkgs.liquidctl}/bin/liquidctl --match kraken set pump speed 80
        ${pkgs.liquidctl}/bin/liquidctl --match kraken set fan speed 20 30 30 50 40 75 50 100
      '';
    };
  };


  environment.variables.EDITOR = "nvim";

  services.openssh.enable = true;

  # -------------------------------------------------------------------------------------------------

  system.stateVersion = "26.05";

}
