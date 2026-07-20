{ config, pkgs, ... }:
{
  services.nginx = {
    enable = true;
    user = "server";

    virtualHosts."www.puppygirls.net" = {
      enableACME = true;
      forceSSL = true;

      root = pkgs.callPackage ./puppygirls { };

      locations."/robots.txt" = {
        extraConfig = ''
          rewrite ^/(.*) $1;
          return 200 "User-agent: *\nDisallow: /";
        '';
      };
    };
  };

  environment.systemPackages = with pkgs; [
  ];

  security.acme = {
    acceptTerms = true;
    defaults.email = "acme-reminders.unwomanly117@passmail.net";
  };
}
