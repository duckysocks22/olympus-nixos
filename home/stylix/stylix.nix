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

  stylix.targets.noctalia-shell = {
    enable = true;
    # Stylix changed mPrimary/mSecondary from base05 (neutral grey) to base0D/0E
    # (accent colors) between 25.11 and 26.05. Disable the colors sub-target so
    # we can keep the old neutral look in noctalia.nix without fighting mkMerge.
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

