{ inputs, pkgs, config, ... }:
{
  imports = [ inputs.nixcord.homeModules.nixcord ];

  # Wrap the nixcord-built Discord package with mullvad-exclude so every launch
  # bypasses the VPN tunnel.  symlinkJoin inherits all share/ data (desktop
  # entry, icons) from the original package; we only replace the two bin/
  # symlinks (discord + Discord).
  #
  # writeShellScript is used rather than makeWrapper because makeWrapper checks
  # that the TARGET binary exists inside the build sandbox, and
  # /run/wrappers/bin/mullvad-exclude is only present at runtime (it is a
  # setuid wrapper created by NixOS activation, not a store path).
  home.packages = [
    (let
      discordWrapper = pkgs.writeShellScript "discord" ''
        exec /run/wrappers/bin/mullvad-exclude \
          ${config.programs.nixcord.finalPackage.discord}/opt/Discord/Discord \
          "$@"
      '';
    in pkgs.symlinkJoin {
      name = "discord-mullvad-excluded";
      paths = [ config.programs.nixcord.finalPackage.discord ];
      postBuild = ''
        for bin in discord Discord; do
          rm "$out/bin/$bin"
          ln -s ${discordWrapper} "$out/bin/$bin"
        done
      '';
    })
  ];

  programs.nixcord = {
    enable = true;

    discord = {
      # Let our mullvad-exclude wrapper above own the "discord" binary;
      # nixcord only needs to build the package, not install it.
      installPackage = false;
      vencord.enable = true;
    };

    config = {
      autoUpdate = true;
      autoUpdateNotification = true;
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
        expressionCloner.enable = true;
      };
    };
    quickCss = "
    @import url('https://abbie.github.io/discord-css/import.css');
    @import url(https://codeberg.org/ridge/Discord-Adblock/raw/branch/main/discord-adblock.css);
    ";
  };
}
