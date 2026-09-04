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
  stylix.targets.opencode = {
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
