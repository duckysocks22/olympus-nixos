{ config, ... }:
{
  services.factorio = {
    enable = true;
    openFirewall = true;
    game-name = "PuppyGirl Industries";
    description = "Lead branch of PuppyGirl Industries production line.";
    public = true;
    loadLatestSave = true;
    requireUserVerification = true;
    admins = [
      "foxtrott_"
    ];

    # Facotrio Login Credentials
    extraSettingsFile = "${config.sops.templates."factorio-credentials.json".path}";
  };

  systemd.services.factorio = {
    serviceConfig = {
      User = "server";
      Group = "server";
    };
  };
}
