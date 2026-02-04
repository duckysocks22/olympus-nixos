{
  services.tailscale = {
    enable = true;
  };

  networking = {
    useDHCP = false;
    interfaces.enp34s0.useDHCP = false;

    interfaces.enp34s0.ipv4.addresses = [{
      address = "10.0.0.249";
      prefixLength = 16;
    }];

    defaultGateway = "10.0.0.1";

    # Set DNS servers
    nameservers = [ "100.100.100.100" "9.9.9.9" ];
  };
}
