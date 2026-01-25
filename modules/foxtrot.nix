{ pkgs, ... }:
{
  users.users.foxtrot = {
    isNormalUser = true;
    extraGroups = [
      "audio"
      "input"
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
}
