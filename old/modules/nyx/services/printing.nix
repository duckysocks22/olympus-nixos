{ pkgs, ... }:
{
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      cups-filters
      cups-browsed
      canon-cups-ufr2
    ];
  };

  hardware.sane.enable = true;
}
