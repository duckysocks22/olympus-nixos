{ config, pkgs, ... }:
{
  services.netbird = { 
    package = pkgs.netbird.overrideAttrs {
      version = "0.67.4";
      tag = "v0.67.4";
      hash = "ab1307e6189e4f51e5c05c518bb9699255aff2710e9872324f0e6814a2c5d043";
      };
    clients.${config.networking.hostName} = {

      # Automatically login to your Netbird network with a setup key
      # This is mostly useful for server computers.
      # For manual setup instructions, see the wiki page section below.
      login = {
        enable = true;

        setupKeyFile = "${config.sops.secrets."netbird/client-key".path}";
      };

      # Port used to listen to wireguard connections
      port = 51821;

      # Set this to true if you want the GUI client
      ui.enable = false;

      # This opens ports required for direct connection without a relay
      openFirewall = true;

      # This opens necessary firewall ports in the Netbird client's network interface
      openInternalFirewall = true;
    };
  };
}
