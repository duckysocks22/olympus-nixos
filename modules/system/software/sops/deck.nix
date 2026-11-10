{ inputs, self, ... }:
{
  flake.nixosModules.deckSops =
    {
      inputs,
      config,
      ...
    }:
    let
      common = ../../../../secrets/common.yaml;
    in
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      sops.defaultSopsFile = ../../../../secrets/${config.networking.hostName}.yaml;
      sops.defaultSopsFormat = "yaml";
      sops.useSystemdActivation = true;

      sops.age.keyFile =
        if config.preservation.enable or false then
          "/var/lib/sops-nix/key.txt"
        else
          "${config.users.users.deck.home}/.config/sops/age/keys.txt";

      sops.secrets."samba/local" = {
        mode = "0440";
        owner = config.users.users.deck.name;
        group = config.users.users.deck.group;
        sopsFile = common;
      };

      sops.secrets."networks/bazinga/pass" = {
        sopsFile = common;
      };

      sops.secrets."attic/client-config" = {
        owner = config.users.users.deck.name;
        sopsFile = common;
      };

      sops.secrets."users/deck" = {
        neededForUsers = true;
      };
    };
}
