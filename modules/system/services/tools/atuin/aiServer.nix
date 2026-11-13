{ inputs, ... }:
{
  flake.nixosModules.atuinAIServer =
    {
      config,
      pkgs,
      ...
    }:
    let
      configToml = pkgs.writeText "atuin-ai-config.toml" ''
        port = 1824
        endpoint = "https://opencode.ai/inference/go/openai/v1"
        api_key = { env = "OPENCODE_GO_API_KEY" }

        default_model = "deepseek-v4.1-flash"

        [request.body]
        stream_options = { include_usage = true }

        [request.headers]
        Authorization = "Bearer {{api_key}}"
        user-agent = "atuin-ai-server/1.0"
        x-opencode-session = "9c1d4b7e-2a63-4f18-9e5b-7d0a2c6f8b34"

        [[models]]
        alias = "deepseek-v4.1-flash"
        name = "DeepSeek v4.1 Flash"
        description = "OpenCode Go - DeepSeek v4.1 Flash"
        model = "deepseek-v4.1-flash"
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
