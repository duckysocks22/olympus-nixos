{ inputs, self, ... }:
{
  flake.homeModules.serverSops =
    {
      inputs,
      config,
      ...
    }:
    {
      imports = [ inputs.sops-nix.homeModules.sops ];

      sops.defaultSopsFile = ../../../../secrets/homeSecrets.yaml;
      sops.defaultSopsFormat = "yaml";

      sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

      sops.secrets."atuin/key" = { };

      sops.secrets."fireworks/account-id" = { };
      sops.secrets."fireworks/api-key" = { };

      sops.secrets."aiApiKey/openrouter/apiKey" = {
        sopsFile = ../../../../secrets/common.yaml;
      };

      sops.secrets."aiApiKey/fireworks/apiKey" = {
        sopsFile = ../../../../secrets/common.yaml;
      };

      sops.secrets."aiApiKey/opencode-go/apiKey" = {
        sopsFile = ../../../../secrets/common.yaml;
      };
    };
}
