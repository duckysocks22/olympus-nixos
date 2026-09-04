{ inputs, config, ... }:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.age.keyFile = "${config.users.users.server.home}/.config/sops/age/keys.txt";

  sops.secrets."users/server" = { };
  sops.secrets."users/foxtrot" = { };
  sops.secrets."netbird/routing-key" = { };
  sops.secrets."caddy/environment" = { };
  sops.secrets."forgejo-runner/environment" = { };
  sops.secrets."remotebuilder/athena" = { };
  sops.secrets."remotebuilder/circe" = { };
  sops.secrets."admin/user" = { };
  sops.secrets."admin/pass" = { };

  sops.secrets."adguardhome/domain_cert" = {
    owner = "server";
    path = "/media/hdd1/certs/dns.puppygirls.net/dns.puppygirls.net.crt";
  };
  sops.secrets."adguardhome/domain_key" = {
    owner = "server";
    path = "/media/hdd1/certs/dns.puppygirls.net/dns.puppygirls.net.key";
  };

  sops.secrets."users/server".neededForUsers = true;

  sops.secrets."copyparty/foxtrot" = {
    mode = "0440";
    owner = "copyparty";
  };

}
