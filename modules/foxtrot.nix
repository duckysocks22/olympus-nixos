{ pkgs, ... }:
{
  users.users.foxtrot = {
    isNormalUser = true;
    home = "/home/foxtrot";
    extraGroups = [
      "audio"
      "input"
      "networkmanager"
      "wheel"
      "cdrom"
    ];
    shell = pkgs.zsh;
  };
  home-manager.users.foxtrot = import ../home/users/foxtrot/core.nix;
  services.displayManager.sessionPackages = [ pkgs.niri ];
}
