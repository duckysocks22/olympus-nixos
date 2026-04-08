{ pkgs, ...}:
{
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [ canon-cups-ufr2 ];

  hardware.printers = {
    ensurePrinters = [
      {
        name = "muse";
        location = "home";
        deviceUri = "http://172.17.100.1:6831/printers/muse";
        model = "drv:///sample.drv/generic.ppd";
        ppdOptions = {
          PageSize = "A4";
        };
      }
    ];
    ensureDefaultPrinter = "muse";
  };
}
