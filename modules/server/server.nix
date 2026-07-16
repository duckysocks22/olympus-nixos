{ pkgs, config, ... }:
{
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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJyzVQusZn11jF8/TqiSWBd+TbPxgKZIM2GK+jvZ7aCN foxtrot@athena-nixos"
    ];
  };

  home-manager.users.server = import ../../home/users/server/core.nix;

  security.sudo.extraRules = [
    {
      users = [ "server" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
