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

  programs.obs-studio = {
    enable = true;

    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-vaapi
      obs-gstreamer
      obs-vkcapture
    ];
  };
}
