{ inputs, ... }:
{
  flake.homeModules.xwayland = { pkgs, ... }: {
    home.packages = [
      pkgs.xwayland-satellite
    ];
  };
}
