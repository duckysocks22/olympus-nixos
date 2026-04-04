{ inputs, ... }:
{
  flake.homeModules.player = { pkgs, ... }: {
    home.packages = with pkgs; [
      vlc
      jellyfin-desktop
      feishin
    ];
  };
}
