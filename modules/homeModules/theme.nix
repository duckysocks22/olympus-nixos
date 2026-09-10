{ inputs, pkgs, ... }: {
  flake.homeModules.stylix =
    {
      lib,
      config,
      pkgs,
      ...
    }:
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
          firefox = {
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
    };
}
