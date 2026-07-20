{ pkgs, ... }:
{
  users.users.minecraft = {
    isSystemUser = true;
    group = "minecraft";
  };

  users.groups.minecraft = { };

  imports = [ ./statech.nix ];
}
