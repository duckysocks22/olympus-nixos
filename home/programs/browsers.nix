{ pkgs, config, lib, inputs, ...}:

{

  home.packages = [
  ];

  programs.firefox = {
    enable = true;
  
    profiles."default" = {
      name = "default";
      userChrome = ''
        .tab-text { font-size: 14px !important; }
      '';
      settings = {
        "brower.startup.homepage" = "https://duckduckgo.com";
        "privacy.resistFingerprinting" = true;
        "browser.in-context.dark-mode" = true;
      };
    };

    policies = {
      DisableTelemtry = true;
      DisableFirefoxStudies = true;
      DisableFirefoxAccounts = true;
      DisableFirefoxScreenshots = true;
      DisableForgetButtom = true;
      DisableMasterPasswordCreation = true;
      DisableProfileImport = true;
      DisableProfileRefresh = true;
      DisableSetDesktopBackground = true;
      DisablePocket = true;
      DisableFormHistory = true;
      DisablePasswordReveal = true;
      BlockAboutConfig = true;
      BlockAboutProfiles = true;
      BlockAboutSupport = true;

      DisplayMenuBar = "never";
      DontCheckDefaultBrowser = true;
      HardwareAcceleration = false;
      OfferToSaveLogins = false;
      DefaultDownloadDirectory = "${config.home.homeDirectory}/Downloads";

      ExtensionSettings = let
        moz = short: "https://addons.modzilla.org/firefox/downloads/latest/${short}/latest.xpi";
      in {
        "*".installation_mode = "blocked";

        "uBlock0@raymondhill.net" = {
          install_url = moz "ublock-origin";
          installation_mode = "force_installed";
          updates_disabled = true;
        };

        "deArrow@ajay.app" = {
          install_url = moz "dearrow";
          installation_mode = "force_installed";
          updates_disabled = true;
        };

        "sponsorBlocker@ajay.app" = {
          install_url = moz "sponsor-block";
          installation_mode = "force_installed";
          updates_disabled = true;
        };

        "vpn@proton.ch" = {
          install_url = moz "protonvpn";
          installation_mode = "force_installed";
          updates_disabled = true;
        };

        "78272b6fa58f4a1abaac99321d503a20@proton.me" = {
          install_url = moz "protonpass";
          installation_mode = "force_installed";
          updates_disabled = true;
        };

        "{e6e36c9a-8323-446c-b720-a176017e38ff}" = {
          install_url = moz "torrent-control";
          installation_mode = "force_installed";
          updates_disabled = true;
        };

        "{99c277af-d778-4a0b-9faa-b1d8165f0a55}" = {
          install_url = moz "nicothin-dark-theme";
          installation_mode = "force_installed";
          updates_disabled = true;
        };

        "{174b2d58-b983-4501-ab4b-07e71203cb43}" = {
          install_url = moz "dark-mode-webextension";
          installation_mode = "force_installed";
          updates_disabled = true;
        };
      };

      "3rdparty".Extensions = {
        "uBlock0@raymondhill.net".adminSettings = {
          userSettings = rec {
          uiTheme            = "dark";
          uiAccentCustom     = true;
          uiAccentCustom0    = "#8300ff";
          cloudStorageEnabled = lib.mkForce false;

          importedLists = [
            "https:#filters.adtidy.org/extension/ublock/filters/3.txt"
            "https:#github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
          ];

          externalLists = lib.concatStringsSep "\n" importedLists;
          };

          selectedFilterLists = [
            "CZE-0"
            "adguard-generic"
            "adguard-annoyance"
            "adguard-social"
            "adguard-spyware-url"
            "easylist"
            "easyprivacy"
            "https:#github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
            "plowe-0"
            "ublock-abuse"
            "ublock-badware"
            "ublock-filters"
            "ublock-privacy"
            "ublock-quick-fixes"
            "ublock-unbreak"
            "urlhaus-1"
          ];
        };
        # Torrent Control Settings
        "{e6e36c9a-8323-446c-b720-a176017e38ff}".adminSettings = {
          
        };
      };
    };
    profiles.default.search = {
      force = true;
      default = "ddg";
      privateDefault = "ddg";

      engines = {
        "Nix Packages" = {
          urls = [
            {
              template = "https://search.nixos.org/packages";
              params = [
                { name = "channel"; value = "25.11"; }
                { name = "query"; value = "{searchTerms}"; }
              ];
            }
          ];
          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = [ "@np" ];
        };

        "Nix Options" = {
          urls = [
            {
              template = "https://search.nixos.org/options";
              params = [
                { name = "channel"; value = "25.11"; }
                { name = "query";   value = "{searchTerms}"; }
              ];
            }
          ];
          icon           = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = [ "@no" ];
        };

        "NixOS Wiki" = {
          urls = [
            {
              template = "https://wiki.nixos.org/w/index.php";
              params = [
                { name = "search"; value = "{searchTerms}"; }
              ];
            }
          ];
          icon           = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = [ "@nw" ];
        };

        "Noogle" = {
          urls = [
            {
              template = "https://noogle.dev/";
              params = [
                { name = "term"; value = "{searchTerms}"; }
              ];
            }
          ];
          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = [ "@noogle" ];
        };
      };
    };
    profiles.default.bookmarks = {
      force = true;
      settings = [
        {
          name = "Bookmarks Bar";
          toolbar = true;
          bookmarks = [
            {
              name = "E-Mail";
              url = "https://mail.proton.me";
              keyword = "mail";
            }
            {
              name = "Torrents";
              toolbar = false;
              bookmarks = [
                {
                  name = "GazelleGames";
                  url = "https://gazellegames.net";
                  keyword = "ggn";
                }
                {
                  name = "qBit - nyx-nixos";
                  url = "http://100.65.34.79:8080";
                  keyword = "qbit";
                }
              ];
            }
          ];
        }
      ];
    };
  };
}
