{ inputs, ... }:
{
  flake.nixosModules.atuinServer =
    {
      config,
      inputs,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.self.nixosModules.atuinAIServer ];

      services.atuin = {
        enable = true;
        package = pkgs.atuin;
        host = "::";
        port = 1823;
        environmentFile = config.sops.secrets."atuin/env".path;

        database = {
          createLocally = true;
        };
      };

      networking.firewall.allowedTCPPorts = [ config.services.atuin.port ];
    };
}
