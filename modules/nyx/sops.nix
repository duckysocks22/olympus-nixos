{ inputs, config, ...}:
{
  imports =
    [
      inputs.sops-nix.nixosModules.sops
    ];

  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.age.keyFile = "${config.users.users.server.home}/.config/sops/age/keys.txt";

  #sops.secrets."webdav/copyparty" = { 
  #  path = "/etc/davfs2/secrets";
  #};

  sops.secrets."samba-nyx/socks" = {};
  sops.secrets."samba-nyx/serena" = {};
  sops.secrets."samba-nyx/zia" = {};
  sops.secrets."users/server" = {};
  sops.secrets."netbird/routing-key" = {};
  sops.secrets."caddy/environment" = {};
  sops.secrets."attic/server-token" = {};
  sops.secrets."forgejo-runner/environment" = {};
  sops.secrets."navidrome/environment" = {};
  sops.secrets."immich/secrets" = {};

  sops.secrets."adguardhome/domain_cert" = {
    owner = "server";
    path = "/media/hdd1/certs/dns.puppygirls.net/dns.puppygirls.net.crt";
  };
  sops.secrets."adguardhome/domain_key" = {
    owner = "server";
    path = "/media/hdd1/certs/dns.puppygirls.net/dns.puppygirls.net.key";
  };

  sops.secrets."factorio_user" = {
    sopsFile = ../../secrets/otherSecrets.json;

    format = "json";
  };

  sops.secrets."factorio_token" = {
    sopsFile = ../../secrets/otherSecrets.json;

    format = "json";
  };

  sops.secrets."factorio_game_password" = {
    sopsFile = ../../secrets/otherSecrets.json;

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
    restartUnits = [ "factorio.service" ];
  };

  sops.secrets."users/server".neededForUsers = true;

  sops.secrets."samba-nyx/socks".mode = "0440";
  sops.secrets."samba-nyx/socks".owner = config.users.users.server.name;
  sops.secrets."samba-nyx/socks".group = config.users.users.server.group;

  sops.secrets."samba-nyx/serena".mode = "0440";
  sops.secrets."samba-nyx/serena".owner = config.users.users.server.name;
  sops.secrets."samba-nyx/serena".group = config.users.users.server.group;

  sops.secrets."samba-nyx/zia".mode = "0440";
  sops.secrets."samba-nyx/zia".owner = config.users.users.server.name;
  sops.secrets."samba-nyx/zia".group = config.users.users.server.group;

  #sops.secrets."netbird/routing-key".owner = "netbird";
  #sops.secrets."netbird/routing-key".group = "netbird";
  

  

  
}
