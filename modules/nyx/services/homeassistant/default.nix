{ config, ... }:
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
      "wake_on_lan"
    ];
    config = {

      "wake_on_lan" = [
        {
          alias = "Wake 'athena-windows'";
          switch = {
            platform = "wake_on_lan";
            mac = "D8-43-AE-54-2A-7E";
            name = "athena-windows";
          };
        }
      ];

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

      homeassistant = {
        internal_url = "http://172.17.100.1:8123";
        external_url = "https://home.puppygirls.net";
      };

      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };

      default_config = { };
    };
  };

  systemd.tmpfiles.rules = [
    "f ${config.services.home-assistant.configDir}/automations.yaml 0644 hass hass"
    "f ${config.services.home-assistant.configDir}/scenes.yaml 0644 hass hass"
    "f ${config.services.home-assistant.configDir}/scripts.yaml 0644 hass hass"
  ];
}
