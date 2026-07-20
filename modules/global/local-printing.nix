{ pkgs, ... }:
{
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    cups-filters
    cups-browsed
    canon-cups-ufr2
  ];
}
