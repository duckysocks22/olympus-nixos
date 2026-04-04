{ inputs, self, ... }:
{
  flake.nixosModules.foxtrot = { pkgs, ... }: {
    imports = [ 
      inputs.home-manager.flakeModules.home-manager
    ];
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
    services.displayManager.sessionPackages = [ pkgs.niri ];
  };
}
