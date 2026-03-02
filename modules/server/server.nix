{ pkgs, ... }:
{
  imports = [
    ./default.nix   
    ./server-network.nix
  ];
  users.users.server = {
    isNormalUser = true;
    home = "/home/server";
    extraGroups = [
      "audio"
      "input"
      "networkmanager"
      "wheel"
      "video"
      "render"
      "cdrom"
    ];
    shell = pkgs.zsh;
  };
  home-manager.users.server = import ../../home/users/server/core.nix;
}
