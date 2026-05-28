{ pkgs, config, ... }:
{
  imports = [
    ./default.nix   
    ./server-network.nix
  ];
  users.users.server = {
    isNormalUser = true;
    home = "/home/server";
    hashedPasswordFile = config.sops.secrets."users/server".path;
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
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcAXHlW7WhNVvoU5H6q7BZDu09Tnd60P8QDJVhpbSiJ foxtrot@circe-nixos"
    ];
  };

  home-manager.users.server = import ../../home/users/server/core.nix;
}
