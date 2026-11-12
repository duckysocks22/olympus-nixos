{ inputs, ... }:
{
  flake.nixosModules.audiobookshelf =
    {
      pkgs-unstable,
      ...
    }:
    {
      services.audiobookshelf = {
        enable = true;
        package = pkgs-unstable.audiobookshelf;
        openFirewall = true;
        user = "server";
        host = "0.0.0.0";
      };
    };
}
