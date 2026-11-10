{ inputs, self, ... }:
{
  flake.nixosModules.serverSops =
    {
      inputs,
      config,
      ...
    }:
    let
      serverShared = ../../../../secrets/server-shared.yaml;
      common = ../../../../secrets/common.yaml;
    in
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      sops.defaultSopsFile = ../../../../secrets/nyx-nixos.yaml;
      sops.defaultSopsFormat = "yaml";
      sops.useSystemdActivation = true;

      sops.age.keyFile = "${config.users.users.server.home}/.config/sops/age/keys.txt";

      sops.secrets."atuin/env" = { };
      sops.secrets."atuin/ai-env" = { };

      sops.secrets."homepage/secrets" = { };

      sops.secrets."llama-cpp/api-key" = {
        mode = "0440";
        owner = config.users.users.server.name;
        group = config.users.users.server.group;
      };
      sops.secrets."finance-summary/env" = { };

      sops.secrets."futo-notes/environment" = {
        owner = config.users.users.futo-notes.name;
        group = config.users.users.futo-notes.group;
        mode = "0600";
        sopsFile = serverShared;
      };

      sops.secrets."pocket-id/encryption" = {
        owner = "pocket-id";
        group = "pocket-id";
      };

      sops.secrets."pocket-id/maxmind" = {
        owner = "pocket-id";
        group = "pocket-id";
      };

      sops.secrets."netbird/coturn/pass" = {
        owner = "turnserver";
        group = "turnserver";
      };

      sops.secrets."netbird/TURN/pass" = {
        owner = "netbird";
        group = "netbird";
      };

      sops.secrets."netbird/datastore/encryption" = {
        owner = "netbird";
        group = "netbird";
      };

      sops.secrets."netbird/turnsecret" = {
        owner = "netbird";
        group = "netbird";
      };

      sops.secrets."netbird/idp/apitoken" = {
        owner = "netbird";
        group = "netbird";
      };

      sops.secrets."netbird/relay/secret" = {
        owner = "netbird";
        group = "netbird";
      };

      sops.secrets."samba-nyx/socks" = { };
      sops.secrets."samba-nyx/serena" = { };
      sops.secrets."samba-nyx/zia" = { };
      sops.secrets."users/server" = {
        sopsFile = serverShared;
        neededForUsers = true;
      };
      sops.secrets."users/foxtrot" = {
        neededForUsers = true;
      };
      sops.secrets."caddy/environment" = {
        sopsFile = serverShared;
      };
      sops.secrets."caddy/ca-cert" = {
        owner = "caddy";
        sopsFile = serverShared;
      };
      sops.secrets."adguardhome/environment" = { };
      sops.secrets."attic/server-token" = { };
      sops.secrets."attic/client-config" = {
        owner = config.users.users.server.name;
        sopsFile = common;
      };
      sops.secrets."forgejo-runner/environment" = { };
      sops.secrets."navidrome/environment" = { };
      sops.secrets."media/freshrss" = {
        owner = "freshrss";
      };
      sops.secrets."immich/secrets" = { };
      sops.secrets."remotebuilder/athena" = { };
      sops.secrets."remotebuilder/circe" = { };
      sops.secrets."admin/user" = { };
      sops.secrets."admin/pass" = { };
      sops.secrets."copyparty/foxtrot" = {
        owner = "copyparty";
      };

      sops.secrets."mollysocket/vapid_privkey" = {
        owner = "mollysocket";
      };
      sops.secrets."factorio_user" = {
        sopsFile = ../../../../secrets/nyx-nixos.json;

        format = "json";
      };

      sops.secrets."factorio_token" = {
        sopsFile = ../../../../secrets/nyx-nixos.json;

        format = "json";
      };

      sops.secrets."factorio_game_password" = {
        sopsFile = ../../../../secrets/nyx-nixos.json;

        format = "json";
      };

      sops.templates."factorio-credentials.json" = {
        content = ''
          {
            "username": "${config.sops.placeholder.factorio_user}",
            "token": "${config.sops.placeholder.factorio_token}",
            "game_password": "${config.sops.placeholder.factorio_game_password}"
          }
        '';

        owner = "server";
        restartUnits = [ "ofsm.service" ];
      };

      sops.secrets."samba-nyx/socks" = {
        mode = "0440";
        owner = config.users.users.server.name;
        group = config.users.users.server.group;
      };

      sops.secrets."samba-nyx/serena" = {
        mode = "0440";
        owner = config.users.users.server.name;
        group = config.users.users.server.group;
      };

      sops.secrets."samba-nyx/zia" = {
        mode = "0440";
        owner = config.users.users.server.name;
        group = config.users.users.server.group;
      };

      sops.secrets."syncthing/pass" = {
        owner = "syncthing";
        sopsFile = common;
      };

      sops.secrets."syncthing/nyx-nixos/cert" = { };
      sops.secrets."syncthing/nyx-nixos/key" = { };
    };
}
