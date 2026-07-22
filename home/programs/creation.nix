{ pkgs, ... }:

let
  # Firefox runs inside `unshare --mount --user --map-root-user`, so any app it
  # launches via GLib (g_app_info_launch_default_for_uri) inherits UID 0 inside
  # the user namespace.  Electron refuses to start as root without --no-sandbox.
  # Override the desktop entry so every invocation (portal or direct) passes it.
  unityhubNoSandbox = pkgs.writeShellScriptBin "unityhub-launcher" ''
    exec ${pkgs.unityhub}/bin/unityhub --no-sandbox "$@"
  '';
in
{
  xdg.desktopEntries.unityhub = {
    name = "Unity Hub";
    exec = "${unityhubNoSandbox}/bin/unityhub-launcher %U";
    terminal = false;
    type = "Application";
    icon = "unityhub";
    comment = "The Official Unity Hub";
    categories = [ "Development" ];
    mimeType = [ "x-scheme-handler/unityhub" ];
    noDisplay = false;
  };

  home.packages = with pkgs; [
    gimp-with-plugins
    gpu-screen-recorder
    gpu-screen-recorder-gtk
    bitwig-studio
    kdePackages.kdenlive
    handbrake
    rawtherapee
    ansel
    unityhub
    blender
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
