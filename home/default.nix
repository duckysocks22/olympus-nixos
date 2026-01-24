{ pkgs, config, ...}:
{
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;

    home-manager.users.foxtrot = import ./users/foxtrot/core.nix;
}
