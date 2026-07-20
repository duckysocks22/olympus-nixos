{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/hermera/disko.nix
    ../../modules/global/system.nix
    ../../modules/global/nix/default.nix
    ../../modules/global/netwatch.nix
    ../../modules/server/sops.nix
    ../../modules/server/server.nix
  ];

  home-manager.users.server = import ../../home/users/server/core.nix;
  home-manager.backupFileExtension = "bak";

  users.mutableUsers = false;
  users.users.root.hashedPasswordFile = config.sops.secrets."users/server".path;

  systemd.sleep.settings.Sleep = {
    AllowSuspend = false;
    AllowHibernation = false;
    AllowHypridSleep = false;
    AllowSuspendThenHibernation = false;
  };

  services.logind.settings.Login.HandeLidSwitch = "ignore";

  networking.hostName = "hermera-nixos";
  networking.networkmanager.enable = lib.mkForce false;
  networking.useDHCP = lib.mkForce false;

  time.timeZone = "America/New_York";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UFT-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UFT-8";
      LC_NAME = "en_US.UFT-8";
      LC_NUMERIC = "en_US.UFT-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UFT-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.trusted-users = [ "nixremote" ];

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
  ];

  services.openssh.enable = true;
  system.stateVersion = "26.05";
}
