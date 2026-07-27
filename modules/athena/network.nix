{ ... }:
{
  networking.networkmanager.unmanaged = [ "interface-name:enp9s0" ];

  networking.interfaces.enp9s0 = {
    ipv4.addresses = [{
      address = "172.17.25.1";
      prefixLength = 16;
    }];
    useDHCP = false;
  };
  networking.defaultGateway = {
    address = "172.17.0.254";
    interface = "enp9s0";
  };
}
