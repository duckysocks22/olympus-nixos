{ pkgs, ... }:
{
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    cups-filters
    cups-browsed
    canon-cups-ufr2
  ];

  hardware.printers.ensurePrinters = [
    {
      name = "Canon-MF270";
      description = "Canon MF270 Series";
      deviceUri = "dnssd://Canon%20MF270%20Series._ipp._tcp.local/?uuid=6d4ff0ce-6b11-11d8-8020-6c3c7c3bf858";
      model = "CNRCUPSMF270ZK.ppd";
    }
  ];
  hardware.printers.ensureDefaultPrinter = "Canon-MF270";
}
