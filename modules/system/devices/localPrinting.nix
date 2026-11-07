{ inputs, self, ... }: {
  flake.nixosModules.localPrinting =
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

      hardware.printers.ensurePrinters = [
        {
          name = "Canon-MF270";
          description = "Canon MF270 Series";
          deviceUri = "ipp://172.17.110.1/ipp/print";
          model = "CNRCUPSMF270ZK.ppd";
        }
      ];
      hardware.printers.ensureDefaultPrinter = "Canon-MF270";
    };
}
