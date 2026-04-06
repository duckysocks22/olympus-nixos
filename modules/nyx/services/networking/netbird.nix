{ config, pkgs, ...}:
{
  services.netbird = {
    package = pkgs.netbird.overrideAttrs {
      version = "0.67.4";
      tag = "v0.67.4";
      hash = "ab1307e6189e4f51e5c05c518bb9699255aff2710e9872324f0e6814a2c5d043";
    };
    clients.nyx-nixos = {
      
      # Automatically login to your Netbird network with a setup key
      # This is mostly useful for server computers.
      # For manual setup instructions, see the wiki page section below.
      login = {
        enable = true;

        # Path to a file containing the setup key for your peer
        # NOTE: if your setup key is reusable, make sure it is not copied to the Nix store.
        setupKeyFile = "${config.sops.secrets."netbird/routing-key".path}";
      };

      environment = {
        NB_ALLOW_SERVER_SSH = "true";
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
    useRoutingFeatures = "both";
  };
}
