{ pkgs, ... }:
{
  users.users.deck = {
    isNormalUser = true;
    home = "/home/deck";
    extraGroups = [
      "audio"
      "input"
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
  home-manager.users.deck = import ../home/users/deck/core.nix;
}
