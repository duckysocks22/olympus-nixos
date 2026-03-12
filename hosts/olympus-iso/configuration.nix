{ inputs, pkgs, lib, ... }:
let
  calamares-nixos-autostart = pkgs.makeAutostartItem {
    name = "calamares";
    package = pkgs.calamares-nixos;
  };
in
{

  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-base.nix"
    ../../modules/foxtrot.nix
    ../../modules/system.nix
    ../../modules/portals.nix
    ../../modules/greeter/cosmic-greeter.nix
    ../../modules/common.nix
    ../../modules/network.nix
    ../../modules/nix/default.nix
  ];

  programs.partition-manager.enable = true;

  environment.systemPackages = with pkgs; [
    calamares-nixos
    calamares-nixos-autostart
    calamares-nixos-extensions
    glibcLocales
  ];

  i18n.supportedLocales = [ "all" ];

  boot = {
    plymouth.enable = lib.mkForce false;
    initrd.systemd.enable = lib.mkForce false;
    kernelPackages = lib.mkForce pkgs.linuxPackages;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  networking.hostName = "olympus-iso";

  users.users.foxtrot = {
    initialPassword = "admin";
  };

  time.timeZone = "America/New_York";

  # Please remove and make own module.....

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

  nixpkgs.config.allowUnfree = true;

  environment.variables.EDITOR = "nvim";
  services.openssh.enable = true;
  #---------------------------------------

  system.stateVersion = lib.trivial.release;
}
