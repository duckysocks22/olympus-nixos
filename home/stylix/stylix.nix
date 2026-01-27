{ pkgs, ... }:
{
  stylix.targets.kitty = {
    enable = true;
    variant256Colors = true;
};
  stylix.targets.gtk = {
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
  };
  stylix.targets.qt = {
    enable = true;
  };
}

