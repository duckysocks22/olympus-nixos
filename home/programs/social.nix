{ inputs, ... }:
{
  flake.homeModules.social = { pkgs, ... }: {
    home.packages = [
      pkgs.signal-desktop
      pkgs.weechat
    ];
  };
}
