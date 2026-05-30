{ pkgs, ...}:

{
  home.packages = [
    pkgs.gimp-with-plugins
    pkgs.gpu-screen-recorder
    pkgs.gpu-screen-recorder-gtk
    pkgs.bitwig-studio
    pkgs.kdePackages.kdenlive
    pkgs.handbrake
    pkgs.rawtherapee
    pkgs.ansel
  ];
}
