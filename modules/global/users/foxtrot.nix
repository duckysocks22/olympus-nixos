{ pkgs, ... }:
{
  users.users.foxtrot = {
    isNormalUser = true;
    home = "/home/foxtrot";
    hashedPassword = "$y$j9T$2hwNZDEGyC/9B2eXztvxA0$HBU2ahHjb1FVCQjGIBbAEoqJlBe1/yzCq/DdSIfyg36";
    extraGroups = [
      "audio"
      "input"
      "networkmanager"
      "wheel"
      "cdrom"
    ];
    shell = pkgs.zsh;
  };
  home-manager.users.foxtrot = import ../../../home/users/foxtrot/core.nix;
  services.displayManager.sessionPackages = [ pkgs.niri ];
}
