{ inputs, config, ...}:
{
  imports =
    [
      inputs.sops-nix.nixosModules.sops
    ];

  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.age.keyFile = "${config.users.users.server.home}/.config/sops/age/keys.txt";

  sops.secrets."webdav/copyparty" = { 
    path = "/etc/davfs2/secrets";
  };
  
}
