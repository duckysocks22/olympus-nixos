{ pkgs, config, lib, inputs, ...}:
let
  hmFirefox = config.programs.firefox.finalPackage;
  emptyFile = pkgs.writeText "empty" "";
  firefoxNoHardened = pkgs.writeShellScriptBin "firefox" ''
    exec ${pkgs.util-linux}/bin/unshare --mount --user --map-root-user \
      ${pkgs.bash}/bin/bash -c "${pkgs.util-linux}/bin/mount --bind ${emptyFile} /etc/ld-nix.so.preload && exec ${hmFirefox}/bin/firefox \"\$@\"" -- "$@"
  '';
in
{

  home.packages = [
    (lib.hiPrio firefoxNoHardened)
  ];

  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
  
    profiles."default" = {
      name = "default";
      userChrome = ''
        .tab-text { font-size: 14px !important; }
      '';
      settings = {
        "browser.startup.homepage" = "https://kagi.com/";
        "browser.theme.toolbar-theme" = 0;
        "browser.theme.content-theme" = 0;
        "ui.systemUsesDarkTheme" = 1;
        "layout.css.prefers-color-scheme.content-override" = 0;
      };
    };

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisableFirefoxAccounts = true;
      DisableFirefoxScreenshots = true;
      DisableForgetButton = true;
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
      NewTabPage = false;
      FirefoxHome = {
        Search = true;
        SponsoredTopSites = false;
        Highlights = false;
        Stories = false;
        SponsoredStories = false;
        Snippets = false;
      };

      DisplayMenuBar = "never";
      DontCheckDefaultBrowser = true;
      HardwareAcceleration = false;
      OfferToSaveLogins = false;
      DefaultDownloadDirectory = "${config.home.homeDirectory}/Downloads";

      ExtensionSettings = let
        moz = short: "https://addons.mozilla.org/firefox/downloads/latest/${short}/latest.xpi";
      in {
        "*".installation_mode = "blocked";

        "uBlock0@raymondhill.net" = {
          install_url = moz "ublock-origin";
          installation_mode = "force_installed";
          updates_disabled = false;
        };

        "search@kagi.com" = {
          install_url = moz "kagi-search-for-firefox";
          installation_mode = "force_installed";
          updates_disabled = false;
        };

        "deArrow@ajay.app" = {
          install_url = moz "dearrow";
          installation_mode = "force_installed";
          updates_disabled = false;
        };

        "sponsorBlocker@ajay.app" = {
          install_url = moz "sponsorblock";
          installation_mode = "force_installed";
          updates_disabled = false;
        };

        "jid0-TgBNh976zF55Pb4ABiM1DXsJV4Q@jetpack" = {
          install_url = moz "startupapps";
          installation_mode = "force_installed";
          updates_disabled = true;
        };

        "PipedRedirect@janigma.com" = {
          install_url = moz "pipedredirectjanigma";
          installation_mode = "force_installed";
          updates_disabled = true;
        };

        "firefox-extension@steamdb.info" = {
          install_url = moz "steam-database";
          installation_mode = "force_installed";
          updates_disabled = false;
        };

        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = moz "bitwarden-password-manager";
          installation_mode = "force_installed";
          updates_disabled = false;
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

        "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}" = {
          install_url = moz "violentmonkey";
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
      default = "kagi";
      privateDefault = "kagi";

      engines = {
        kagi = {
          name = "Kagi";
          urls = [
            {
              template = "https://kagi.com/search";
              params = [
                { name = "q"; value = "{searchTerms}"; }
              ];
            }
          ];
          definedAliases = [ "@kagi" ];
        };

        protondb = {
          name = "ProtonDB";
          urls = [
            {
              template = "https://www.protondb.com/search";
              params = [
                { name = "q"; value = "{searchTerms}"; }
              ];
            }
          ];
          definedAliases = [ "@proton" ];
        };

        "Nix Packages" = {
          urls = [
            {
              template = "https://search.nixos.org/packages";
              params = [
                { name = "channel"; value = "26.05"; }
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
                { name = "channel"; value = "26.05"; }
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
              name = "Archive of Our Own";
              url = "https://archiveofourown.org/";
              keyword = "ao3";
            }
            {
              name = "How Long To Beat";
              url = "https://howlongtobeat.com/";
              keyword = "hltb";
            }
            {
              name = "Shopping";
              toolbar = false;
              bookmarks = [
                {
                  name = "SteamDB";
                  url = "https://steamdb.info/";
                  keyword = "stb";
                }
                {
                  name = "IsThereAnyDeal?";
                  url = "https://www.isthereanydeal.com";
                  keyword = "itad";
                }
                {
                  name = "Unofficial Deals";
                  url = "https://gg.deals";
                  keyword = "keydeal";
                }
                {
                  name = "Deku Deals";
                  url = "https://www.dekudeals.com";
                  keyword = "deku";
                }
                {
                  name = "Humble Bundle";
                  url = "https://www.humblebundle.com";
                  keyword = "humble";
                }
                {
                  name = "Exchange";
                  url = "https://swap.bitania.com";
                  keyword = "coin";
                }
              ];
            }
            {
              name = "Torrents";
              toolbar = false;
              bookmarks = [
                {
                  name = "qBit - nyx-nixos";
                  url = "https://qbit.olympus.moe";
                  keyword = "qbit";
                }
                {
                  name = "SkullXDCC";
                  url = "https://xdcc-search.com/";
                  keyword = "skull";
                }
                {
                  name = "XDDC.eu";
                  url = "https://xdcc.eu";
                  keyword = "skulleu";
                }
                {
                  name = "FMHY";
                  url = "https://fmhy.net";
                  keyword = "fmhy";
                }
                {
                  name = "GOG Games Downloader";
                  url = "https://gog-games.to";
                  keyword = "gog";
                }
                {
                  name = "FitGirl Repacks";
                  url = "https://fitgirl-repacks.site";
                  keyword = "fitgirl";
                }
                {
                  name = "Private Trackers";
                  toolbar = false;
                  bookmarks = [
                    {
                      name = "GazelleGames";
                      url = "https://gazellegames.net";
                      keyword = "ggn";
                    }
                    {
                      name = "SeedPool";
                      url = "https://seedpool.org";
                      keyword = "seed";
                    }
                    {
                      name = "Orpheus Network";
                      url = "https://orpheus.network/";
                      keyword = "orph";
                    }
                  ];
                }
                {
                  name = "Public Trackers";
                  toolbar = false;
                  bookmarks = [
                    {
                      name = "nyaa.si";
                      url = "https://nyaa.si";
                      keyword = "nya";
                    }
                  ];
                }
                {
                  name = "Tools";
                  toolbar = false;
                  bookmarks = [
                    {
                      name = "GGn Userscripts";
                      url = "https://gazellegames.net/wiki.php?action=article&id=633";
                      keyword = "ggnscript";
                    }
                    {
                      name = "GGn Mass Downloader";
                      url = "https://gazellegames.net/wiki.php?action=article&id=445";
                      keyword = "ggndown";
                    }
                    {
                      name = "GGn Status";
                      url = "https://ggn.trackerstatus.info";
                      keyword = "ggnstat";
                    }
                  ];
                }
              ];
            }
            {
              name = "HomeLab";
              toolbar = false;
              bookmarks = [
                {
                  name = "Navidrome";
                  url = "http://100.111.146.104:4533";
                  keyword = "navi";
                }
                {
                  name = "NextDNS";
                  url = "https://my.nextdns.io/";
                  keyword = "dns";
                }
              ];
            }
            {
              name = "Development";
              toolbar = false;
              bookmarks = [
                {
                  name = "Nixpkgs Manual";
                  url = "https://nixos.org/manual/nixpkgs/stable/";
                  keyword = "manpkg";
                }
                {
                  name = "XP.css";
                  url = "https://botoxparty.github.io/XP.css/";
                  keyword = "xpcss";
                }
              ];
            }
            {
              name = "Social";
              toolbar = false;
              bookmarks = [
                {
                  name = "The Lounge";
                  url = "http://[::1]:9000";
                  keyword = "irc";
                }
              ];
            }
            {
              name = "Information";
              toolbar = false;
              bookmarks = [
                {
                  name = "Linux";
                  toolbar = false;
                  bookmarks = [
                    {
                      name = "Nixpkgs Manual";
                      url = "https://www.nixos.org/manual/nixpkgs/stable";
                      keyword = "npman";
                    }
                    {
                      name = "Command Line Gems";
                      url = "https://www.commandlinefu.com/commands/browse";
                      keyword = "cmd";
                    }
                    {
                      name = "The Linux Documentation Project";
                      url = "https://tldp.org/index.html";
                      keyword = "tldp";
                    }
                    {
                      name = "pure-sh-bible";
                      url = "https://github.com/dylanaraps/pure-sh-bible";
                      keyword = "sh";
                    }
                    {
                      name = "pure-bash-bible";
                      url = "https://github.com/dylanaraps/pure-bash-bible";
                      keyword = "bash";
                    }
                    {
                      name = "OverTheWire";
                      url = "https://overthewire.org/wargames/";
                      keyword = "otw";
                    }
                  ];
                }
                {
                  name = "Awesome Lists";
                  url = "https://github.com/sindresorhus/awesome?tab=readme-ov-file";
                  keyword = "awelist";
                }
              ];
            }
          ];
        }
      ];
    };
  };
}
