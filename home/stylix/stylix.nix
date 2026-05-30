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
    colors.enable = true;
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

