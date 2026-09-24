{ inputs, pkgs, ... }: {
  flake.homeModules.stylix =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      h = config.lib.stylix.colors.withHashtag;
      piTheme = pkgs.writeText "pi-theme-stylix.json" (
        builtins.toJSON {
          "$schema" = "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
          name = "stylix";
          vars = {
            bg = h.base00;
            surface = h.base01;
            surface2 = h.base02;
            gray = h.base03;
            gray2 = h.base04;
            fg = h.base05;
            fg2 = h.base06;
            fgBright = h.base07;
            red = h.red;
            orange = h.orange;
            yellow = h.yellow;
            green = h.green;
            cyan = h.cyan;
            blue = h.blue;
            magenta = h.magenta;
            pink = h.brown;
          };
          colors = {
            accent = "blue";
            border = "surface2";
            borderAccent = "blue";
            borderMuted = "surface";
            success = "green";
            error = "red";
            warning = "yellow";
            muted = "gray2";
            dim = "gray";
            text = "";
            thinkingText = "gray2";
            scrollbarTrack = "surface";
            scrollbarThumb = "gray";
            selectedBg = "surface";
            searchMatchBg = "surface2";
            searchMatchText = "fg";
            userMessageBg = "surface";
            userMessageText = "fgBright";
            customMessageBg = "surface";
            customMessageText = "fg";
            customMessageLabel = "blue";
            toolPendingBg = "surface";
            toolSuccessBg = "#253a30";
            toolErrorBg = "#42282c";
            toolTitle = "blue";
            toolOutput = "gray2";
            mdHeading = "yellow";
            mdLink = "blue";
            mdLinkUrl = "gray";
            mdCode = "cyan";
            mdCodeBlock = "fg2";
            mdCodeBlockBorder = "surface2";
            mdQuote = "gray2";
            mdQuoteBorder = "surface2";
            mdHr = "surface2";
            mdListBullet = "cyan";
            toolDiffAdded = "green";
            toolDiffRemoved = "red";
            toolDiffContext = "gray";
            syntaxComment = "gray";
            syntaxKeyword = "magenta";
            syntaxFunction = "blue";
            syntaxVariable = "orange";
            syntaxString = "green";
            syntaxNumber = "pink";
            syntaxType = "cyan";
            syntaxOperator = "gray2";
            syntaxPunctuation = "gray";
            thinkingOff = "surface2";
            thinkingMinimal = "gray";
            thinkingLow = "cyan";
            thinkingMedium = "blue";
            thinkingHigh = "magenta";
            thinkingXhigh = "pink";
            thinkingMax = "red";
            bashMode = "orange";
          };
          export = {
            pageBg = "bg";
            cardBg = "surface";
            infoBg = "#3d3226";
          };
        }
      );
    in
    {
      imports = [ inputs.stylix.homeModules.stylix ];

      stylix = {
        enable = true;
        autoEnable = false;
        polarity = "dark";
        base16Scheme = "${pkgs.base16-schemes}/share/themes/paraiso.yaml";
        fonts = {
          serif = {
            package = pkgs.cascadia-code;
            name = "Cascadia Code";
          };
          sansSerif = {
            package = pkgs.noto-fonts;
            name = "Noto Sans";
          };
          monospace = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrains Mono";
          };
          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };
          sizes = {
            applications = 10;
            terminal = 10;
          };
        };
        targets = {
          kitty = {
            enable = true;
            variant256Colors = true;
          };
          gtk.enable = true;
          opencode.enable = true;
          gnome.enable = true;
          librewolf = {
            enable = true;
            profileNames = [ "default" ];
            firefoxGnomeTheme.enable = true;
          };
          qt.enable = true;
          kde.enable = true;
          nixvim.enable = true;
          btop.enable = true;
        };
      };

      home.file.".pi/agent/themes/stylix.json".source = piTheme;
      programs.pi-coding-agent.settings.theme = "stylix";

      programs.kitty.extraConfig =
        let
          digits = "0123456789abcdef";
          parseHex = s: (builtins.fromTOML "v = 0x${builtins.substring 1 6 s}").v;
          nibble = n: builtins.substring n 1 digits;
          toHex2 =
            v:
            let
              x = builtins.floor (v + 0.5);
              hi = builtins.div x 16;
              lo = x - hi * 16;
            in
            "${nibble hi}${nibble lo}";
          tonalMix =
            hex: t:
            let
              c = parseHex hex;
              b = parseHex h.base00;
              cr = builtins.div c 65536;
              ct = c - cr * 65536;
              cg = builtins.div ct 256;
              cb = ct - cg * 256;
              br = builtins.div b 65536;
              bt = b - br * 65536;
              bg = builtins.div bt 256;
              bb = bt - bg * 256;
              blend = x: y: toHex2 (x * (1 - t) + y * t);
            in
            "#${blend cr br}${blend cg bg}${blend cb bb}";
          tone = hex: tonalMix hex 0.3;
        in
        ''
          color1 ${tone h.red}
          color2 ${tone h.green}
          color3 ${tone h.yellow}
          color4 ${tone h.blue}
          color6 ${tone h.cyan}
          color9 ${tone h.red}
          color10 ${tone h.green}
          color11 ${tone h.yellow}
          color12 ${tone h.blue}
          color14 ${tone h.cyan}
          color16 ${tone h.orange}
          color17 ${tone h.brown}
        '';
    };
}
