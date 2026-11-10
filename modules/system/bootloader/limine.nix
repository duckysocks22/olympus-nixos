{ inputs, self, ... }:
{
  flake.nixosModules.limine =
    {
      ...
    }:
    {
      boot.loader.efi.canTouchEfiVariables = false;

      boot.loader.limine = {
        enable = true;
        secureBoot.enable = false;
        efiInstallAsRemovable = true;
      };
    };
}
