{ inputs, ... }:
{
  flake.nixosModules.printing =
    {
      pkgs,
      ...
    }:
    {
      services.printing = {
        enable = true;
        startWhenNeeded = true;
        browsed.enable = false;

        drivers = with pkgs; [
          cups-filters
          canon-cups-ufr2
        ];
      };
    };
}
