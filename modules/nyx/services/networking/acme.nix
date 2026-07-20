{ config, pkgs, ... }:
let
  domainName = "puppygirls.net";
in
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "cloudflare.tissue485@passmail.net";
    certs = {
      "${domainName}" = {
        domain = "*.${domainName}";
        dnsProvider = "cloudflare";
        group = "adguardhome";
        credentialFiles = {
          CLOUDFLARE_DNS_API_TOKEN_FILE = "${config.sops.secrets."cloudflare/api".path}";
        };
        postRun = ''
          ${pkgs.acl}/bin/setfacl -m \
          u:adguardhome:rx \
          /var/lib/acme/${domainName}

          ${pkgs.acl}/bin/setfacl -m \
          u:adguardhome:r \
          /var/lib/acme/${domainName}/*.pem
        '';
        reloadServices = [
          "adguardhome"
        ];
      };
    };
  };
  /*
    systemd.services."acme-order-renew-${domainName}" = {
      serviceConfig = {
        LoadCredential = [
          "target:${config.sops.secrets."cloudflare/api".path}"
        ];
        Environment = [
          "CLOUDFLARE_DNS_API_TOKEN=%d/target"
        ];
      };
    };
  */
}
