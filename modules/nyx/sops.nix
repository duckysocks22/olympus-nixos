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

  sops.secrets."samba/socks" = {};
  sops.secrets."samba/serena" = {};
  sops.secrets."samba/zia" = {};
  sops.secrets."users/server" = {};

  sops.secrets."users/server".neededForUsers = true;

  sops.secrets."samba/socks".mode = "0440";
  sops.secrets."samba/socks".owner = config.users.users.server.name;
  sops.secrets."samba/socks".group = config.users.users.server.group;

  sops.secrets."samba/serena".mode = "0440";
  sops.secrets."samba/serena".owner = config.users.users.server.name;
  sops.secrets."samba/serena".group = config.users.users.server.group;

  sops.secrets."samba/zia".mode = "0440";
  sops.secrets."samba/zia".owner = config.users.users.server.name;
  sops.secrets."samba/zia".group = config.users.users.server.group;
  

  

  
}
