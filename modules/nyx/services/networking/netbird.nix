{
  services.netbird = {
    useRoutingFeatures = "both";
    clients.nyx-nixos = {
      login = {
        enable = true;

        setupKeyFile = "${config.sops.secrets."netbird/routing-key".path}";
      };

      port = 51821;
      openFirewall = true;
      openInternalFirewall = true;

      ui.enable = true;

    };
  };
}
