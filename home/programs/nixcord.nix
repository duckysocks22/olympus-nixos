{ inputs, ... }:
{
  imports = [ inputs.nixcord.homeModules.nixcord ];

  programs.nixcord = {
    enable = true;

    #discord.vencord.enable = true;
    vesktop.enable = true;

    config = {
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
      };
    };
  };
}
