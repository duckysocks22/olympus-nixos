{ pkgs, ... }:
{
  users.users.server = {
    isNormalUser = true;
    home = "/home/server";
    extraGroups = [
      "audio"
      "input"
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
  home-manager.users.server = import ../home/users/server/core.nix;
}
