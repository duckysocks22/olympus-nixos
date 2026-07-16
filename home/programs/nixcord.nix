{ inputs, pkgs, config, lib, ... }:
{
  imports = [ inputs.nixcord.homeModules.nixcord ];

  # Wrap the nixcord-built Discord package with mullvad-exclude so every launch
  # bypasses the VPN tunnel.  symlinkJoin inherits all share/ data (desktop
  # entry, icons) from the original package; we only replace the bin/ symlinks
  # (discord and Discord, both of which point to the same underlying binary).
  #
  # writeShellScript is used rather than makeWrapper because makeWrapper checks
  # that the TARGET binary exists inside the build sandbox, and
  # /run/wrappers/bin/mullvad-exclude is only present at runtime (it is a
  # setuid wrapper created by NixOS activation, not a store path).
  home.packages = [
    (let
      discordWrapper = pkgs.writeShellScript "discord" ''
        exec /run/wrappers/bin/mullvad-exclude \
          ${config.programs.nixcord.finalPackage.discord}/bin/discord \
          "$@"
      '';
    in pkgs.symlinkJoin {
      name = "discord-mullvad-excluded";
      paths = [ config.programs.nixcord.finalPackage.discord ];
      postBuild = ''
        rm "$out/bin/discord"
        ln -s ${discordWrapper} "$out/bin/discord"
        rm "$out/bin/Discord"
        ln -s ${discordWrapper} "$out/bin/Discord"
      '';
    })

    # (let
    #   vesktopWrapper = pkgs.writeShellScript "vesktop" ''
    #     exec /run/wrappers/bin/mullvad-exclude \
    #       ${config.programs.nixcord.finalPackage.vesktop}/bin/vesktop \
    #       "$@"
    #   '';
    # in pkgs.symlinkJoin {
    #   name = "vesktop-mullvad-excluded";
    #   paths = [ config.programs.nixcord.finalPackage.vesktop ];
    #   postBuild = ''
    #     rm "$out/bin/vesktop"
    #     ln -s ${vesktopWrapper} "$out/bin/vesktop"
    #   '';
    # })
  ];

  # Vencord writes quickCss.css atomically (write-tmp + rename), which
  # replaces home-manager's symlink with a regular file.  On the next rebuild
  # checkLinkTargets sees the regular file and aborts the entire activation,
  # so nixcord-vencord-settings never runs and plugins are never applied.
  # force = true tells home-manager to overwrite the regular file with the
  # managed symlink every switch, re-asserting the Nix-declared CSS content.
  home.file."${config.programs.nixcord.configDir}/settings/quickCss.css".force = true;

  programs.nixcord = {
    enable = true;

    discord = {
      enable = true;
      installPackage = false;
      krisp.enable = true;
      vencord.enable = true;
      settings = {
        openasar = { setup = false; };
      };
    };

    config = {
      autoUpdate = true;
      autoUpdateNotification = true;
      useQuickCss = true;
      themeLinks = [
        "https://raw.githubusercontent.com/round-panda/gruvbox-sharp/54f0612a1d0fb38d3f2c7a7f4b697b5ad607d312/GruvboxSharp.theme.css"
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
        expressionCloner.enable = true;
      };
    };
    quickCss = "
    @import url('https://abbie.github.io/discord-css/import.css');
    @import url(https://codeberg.org/ridge/Discord-Adblock/raw/branch/main/discord-adblock.css);
    ";
  };
}
