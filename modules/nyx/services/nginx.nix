{
  services.nginx = {
    enable = false;
    virtualHosts."nyx-nixos.local"= {
      locations."/" = {
        return = "200 '<html><body>It works</body></html>'";
        extraConfig =- ''
          default_type text/html;
        '';
      };
    };
  };
}
