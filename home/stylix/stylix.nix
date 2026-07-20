{ pkgs, ... }:
{
  stylix.polarity = "dark";
  stylix.targets.kitty = {
    enable = true;
    variant256Colors = true;
  };
  stylix.targets.gtk = {
    enable = true;
  };

  stylix.targets.gnome = {
    enable = true;
  };

  stylix.targets.firefox = {
    enable = true;
    profileNames = [ "default" ];
    inputs.enable = true;
    fonts.enable = true;
    # Disabled: this injects a userContent.css that paints every page in the
    # base16 palette with !important, which masks prefers-color-scheme and
    # produces broken mixed-mode rendering on sites with their own dark CSS.
    # Manual prefs in home/programs/browsers.nix drive dark-mode now.
    colors.enable = false;
  };

  # Stylix's noctalia-shell target is disabled; colors are set manually in
  # noctalia.nix to preserve the pre-26.05 neutral grey look (base05/base04)
  # instead of the new accent-based mapping (base0D/0E).
  stylix.targets.noctalia-shell.enable = false;
  stylix.targets.qt = {
    enable = true;
  };
  stylix.targets.nixvim = {
    enable = true;
  };

  stylix.targets.btop = {
    enable = true;
    colors.enable = true;
  };
}
