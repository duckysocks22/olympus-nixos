{ pkgs, ...}:

{
  home.packages = [
    pkgs.gimp-with-plugins
    pkgs.gpu-screen-recorder
    pkgs.gpu-screen-recorder-gtk
    pkgs.blender-hip
    pkgs.bitwig-studio
    pkgs.kdePackages.kdenlive
    pkgs.handbrake
  ];
}
