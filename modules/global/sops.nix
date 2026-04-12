{ inputs, config, ...}:
{
  imports =
    [
      inputs.sops-nix.nixosModules.sops
    ];

  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.age.keyFile = "${config.users.users.foxtrot.home}/.config/sops/age/keys.txt";

  sops.secrets."samba/local" = { 
    path = "/etc/nixos/smb-secrets";
  };

  sops.secrets."samba/local".neededForUsers = true;
  sops.secrets."samba/local".mode = "0440";
  sops.secrets."samba/local".owner = config.users.users.foxtrot.name;
  sops.secrets."samba/local".group = config.users.users.foxtrot.group;

  sops.secrets."netbird/client-key" = { 
    owner = "foxtrot";
  };
  
}
