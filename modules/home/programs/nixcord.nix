{ inputs, self, ... }:
{
  flake.homeModules.nixcord =
    {
      inputs,
      pkgs,
      config,
      lib,
      ...
    }:
    {
      imports = [ inputs.nixcord.homeModules.nixcord ];

      home.packages = [
        (
          let
            discordWrapper = pkgs.writeShellScript "discord" ''
              exec /run/wrappers/bin/mullvad-exclude \
                ${config.programs.nixcord.finalPackage.discord}/bin/discord \
                "$@"
            '';
          in
          pkgs.symlinkJoin {
            name = "discord-mullvad-excluded";
            paths = [ config.programs.nixcord.finalPackage.discord ];
            postBuild = ''
              rm "$out/bin/discord"
              ln -s ${discordWrapper} "$out/bin/discord"
              rm "$out/bin/Discord"
              ln -s ${discordWrapper} "$out/bin/Discord"
            '';
          }
        )
      ];

      home.file."${config.programs.nixcord.configDir}/settings/quickCss.css".force = true;

      home.file."${config.programs.nixcord.configDir}/themes/dank-discord.css" = {
        source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/Vencord/themes/dank-discord.css";
        force = true;
      };

      programs.nixcord = {
        enable = true;

        discord = {
          enable = true;
          installPackage = false;
          krisp.enable = true;
          vencord.enable = false;
          equicord.enable = true;
          commandLineArgs = [
            "--enable-features=WebRTCPipeWireCapturer"
            "--disable-gpu"
          ];
          settings = {
            openasar = {
              setup = true;
              quickstart = true;
            };
          };
        };

        config = {
          autoUpdate = true;
          autoUpdateNotification = true;
          useQuickCss = true;
          themeLinks = [
            #"https://capnkitten.github.io/Material-Discord/Material-Discord.theme.css"
          ];
          enabledThemes = [
            "dank-discord.css"
          ];
          frameless = true;
          plugins = {
            noBlockedMessages = {
              enable = true;
              allowAutoModMessages = true;
              alsoHideIgnoredUsers = true;
              disableNotifications = true;
              hideBlockedUserReplies = true;
            };
            replaceGoogleSearch = {
              enable = true;
              customEngineName = "DuckDuckGo";
              customEngineUrl = "https://duckduckgo.com/";
            };
            dearrow = {
              enable = true;
              dearrowByDefault = true;
              hideButton = true;
              replaceElements = 0;
            };
            typingIndicator.enable = true;
            betterSettings.enable = true;
            betterUploadButton.enable = true;
            fixImagesQuality.enable = true;
            fixYoutubeEmbeds.enable = true;
            youtubeAdblock.enable = true;
            clearUrls.enable = true;
            messageLinkEmbeds.enable = true;
            translate.enable = true;
            unindent.enable = true;
            volumeBooster.enable = true;
            fakeNitro.enable = true;
            usrbg.enable = true;
            customRpc.enable = true;
            newGuildSettings.enable = true;
            noF1.enable = true;
            petpet.enable = true;
            expressionManager.enable = true;
            anonymiseFileNames = {
              enable = true;
              anonymiseByDefault = true;
              method = 0;
            };
          };
        };
        quickCss = "
      @import url('https://abbie.github.io/discord-css/import.css');
      @import url(https://codeberg.org/ridge/Discord-Adblock/raw/branch/main/discord-adblock.css);

      .theme-dark {
          --main-color hsl(20,7%,9%) - hsl (0,0%,98%
      }
      ";
      };
    };
}
