{ config, ...}:
{

  imports = [
    ./govee2mqtt.nix
  ];

  services.home-assistant = {
    enable = true;
    extraComponents = [
      # Components required to complete the onboarding
      "analytics"
      "google_translate"
      "met"
      "radio_browser"
      "shopping_list"
      # Recommended for fast zlib compression
      # https://www.home-assistant.io/integrations/isal
      "isal"
      "samsungtv"
      "govee_light_local"
      "mqtt"
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      
      "automation sunset_lights" = [
        {
          alias = "Turn on lights at sunset";
          triggers = {
            trigger = "numeric_state";
            entity_id = "sun.sun";
            attribute = "elevation";
            below = "-3.0";
          };
          actions = {
            action = "light.turn_on";
            entity_id = "all";
          };
        }
      ];
      "automation sunrise_lights" = [
        {
          alias = "Turn off lights at sunrise";
          triggers = {
            trigger = "numeric_state";
            entity_id = "sun.sun";
            attribute = "elevation";
            above = "-3.0";
          };
          actions = {
            action = "light.turn_off";
            entity_id = "all";
          };
        }
      ];
      "automation ui" = "!include automations.yaml";
      "scene ui" = "!include scenes.yaml";
      "script ui" = "!include scripts.yaml";

      "lights" = [
        {
          unique_id = "light.all_lights";
          platform = "group";
          entities = [
            "light.h6004_20de"
            "light.h6004_c2be"
            "light.h8072_796f"
          ];
        }
      ];

      default_config = {};
    };
  };

  systemd.tmpfiles.rules = [
    "f ${config.services.home-assistant.configDir}/automations.yaml 0644 hass hass"
    "f ${config.services.home-assistant.configDir}/scenes.yaml 0644 hass hass"
    "f ${config.services.home-assistant.configDir}/scripts.yaml 0644 hass hass"
  ];
}
