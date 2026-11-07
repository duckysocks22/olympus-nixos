{ inputs, self, ... }:
{
  flake.homeModules.atuin =
    {
      config,
      pkgs,
      pkgs-unstable,
      ...
    }:
    {
      programs.atuin = {
        enable = true;
        package = pkgs-unstable.atuin;
        settings = {
          auto_sync = true;
          sync_frequency = "5m";
          sync_address = "http://192.168.10.253:1823";
          search_mode = "fuzzy";

          ai = {
            enabled = true;
            model = "glm-5.3-flash";
            endpoint = "http://192.168.10.253:1824";
            endpoint_protocol = "oss";
          };

          key_path = config.sops.secrets."atuin/key".path;
        };
      };
    };
}
