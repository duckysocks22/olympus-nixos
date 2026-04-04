{ inputs, ... }:
{
  flake.homeModules.nixcord = { inputs, ... }: {
    imports = [ inputs.nixcord.homeModules.nixcord ];

    programs.nixcord = {
      enable = true;

      #discord.vencord.enable = true;
      vesktop.enable = true;

      config = {
        useQuickCss = true;
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
            customEngineURL = "https://duckduckgo.com/";
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
          ClearURLs.enable = true;
          messageLinkEmbeds.enable = true;
          translate.enable = true;
          unindent.enable = true;
          iLoveSpam.enable = true;
          volumeBooster.enable = true;
          fakeNitro.enable = true;
          USRBG.enable = true;
          CustomRPC.enable = true;
          newGuildSettings.enable = true;
          noF1.enable = true;
          petpet.enable = true;
          expressionCloner.enable = true;
        };
      };
      quickCss = "
      @import url('https://abbie.github.io/discord-css/import.css');
      @import url(https://codeberg.org/ridge/Discord-Adblock/raw/branch/main/discord-adblock.css);
      ";
    };
  };
}
