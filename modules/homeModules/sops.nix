{ inputs, self, ... }:
{
  flake.homeModules.foxtrotSops = { inputs, config, ... }: {
    imports = [ inputs.sops-nix.homeModules.sops ];

    sops.defaultSopsFile = ../../secrets/homeSecrets.yaml;
    sops.defaultSopsFormat = "yaml";
    
    sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    sops.secrets."atuin/key" = { };
  };

  flake.homeModules.serverSops = { inputs, config, ... }: {
    imports = [ inputs.sops-nix.homeModules.sops ];

    sops.defaultSopsFile = ../../secrets/homeSecrets.yaml;
    sops.defaultSopsFormat = "yaml";
    
    sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    sops.secrets."atuin/key" = { };
  };

  flake.homeModules.deckSops = { inputs, config, ... }: {
    imports = [ inputs.sops-nix.homeModules.sops ];

    sops.defaultSopsFile = ../../secrets/homeSecrets.yaml;
    sops.defaultSopsFormat = "yaml";
    
    sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    sops.secrets."atuin/key" = { };
  };
}
