{ inputs, self, ... }:
{
  flake.nixosModules.foxtrot = { pkgs, ... }: {
    modules = [
      self.homeConfigurations.foxtrot
      self.homeModules.functions
      self.homeModules.git
      self.homeModules.browsers
      self.homeModules.home-common
      self.homeModules.creation
      self.homeModules.download
      self.homeModules.easyeffects
      self.homeModules.launchers
      self.homeModules.nixcord
      self.homeModules.nixvim
      self.homeModules.player
      self.homeModules.social
      self.homeModules.stylix
      self.homeModules.qbittorrent
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
