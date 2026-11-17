{ inputs, ... }:
{
  flake.nixosModules.olympus-canon = {
    hardware.printers.ensurePrinters = [
      {
        name = "Olympus-Canon-MF270";
        description = "Olympus Canon MF270 Series";
        deviceUri = "ipp://172.17.110.1/ipp/print";
        model = "CNRCUPSMF270ZK.ppd";
      }
    ];

    hardware.printers.ensureDefaultPrinter = "Olympus-Canon-MF270";
  };
}
