{ inputs, self, ... }:
{
  flake.nixosModules.atuinServer =
    {
      config,
      pkgs,
      ...
    }:
    {
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

  flake.nixosModules.atuinAIServer =
    {
      config,
      pkgs,
      ...
    }:
    let
      configToml = pkgs.writeText "atuin-ai-config.toml" ''
        port = 1824
        endpoint = "https://api.fireworks.ai/inference/v1"
        api_key = { env = "FIREWORKS_API_KEY" }

        default_model = "glm-5p3-flash"

        [request.body]
        stream_options = { include_usage = true }

        [request.headers]
        Authorization = "Bearer {{api_key}}"
        user-agent = "atuin-ai-server/1.0"
        x-opencode-session = "9c1d4b7e-2a63-4f18-9e5b-7d0a2c6f8b34"

        [[models]]
        alias = "glm-5p3-flash"
        name = "GLM 5.3 Flash"
        description = "Fireworks API - GLM Flash Latest"
        model = "accounts/fireworks/routers/glm-5p3-flash"
      '';
    in
    {
      virtualisation.oci-containers.containers."atuin-ai-server" = {
        image = "ghcr.io/atuinsh/atuin-ai-server:latest";
        environmentFiles = [ config.sops.secrets."atuin/ai-env".path ];
        volumes = [ "${configToml}:/etc/atuin-ai/config.toml:ro" ];
        log-driver = "journald";
        extraOptions = [
          "--network=host"
        ];
      };

      networking.firewall.allowedTCPPorts = [ 1824 ];
    };
}
