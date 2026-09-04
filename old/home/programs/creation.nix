{ pkgs, ... }:

let
  # Firefox runs inside `unshare --mount --user --map-root-user`, so any app it
  # launches via GLib (g_app_info_launch_default_for_uri) inherits UID 0 inside
  # the user namespace.  Electron refuses to start as root without --no-sandbox.
  # Override the desktop entry so every invocation (portal or direct) passes it.
  unityhubNoSandbox = pkgs.writeShellScriptBin "unityhub-launcher" ''
    exec ${pkgs.unityhub}/bin/unityhub --no-sandbox "$@"
  '';
  davinci-resolveWrapped = pkgs.writeShellScriptBin "davinci-resolve" ''
    export QT_QPA_PLATFORM=xcb
    export RUSTICL_ENABLE=radeonsi
    export OCL_ICD_VENDORS="${pkgs.mesa.opencl}/etc/OpenCL/vendors"
    exec ${pkgs.davinci-resolve}/bin/davinci-resolve "$@"
  '';
  resolveTranscode = pkgs.writeShellScriptBin "resolve-transcode" ''
    set -eu
    export PATH="${pkgs.coreutils}/bin:$PATH"
    FFMPEG="${pkgs.ffmpeg}/bin/ffmpeg"
    FFPROBE="${pkgs.ffmpeg}/bin/ffprobe"

    case "''${1:-}" in
      ""|-h|--help)
        cat <<'EOF'
Usage: resolve-transcode <folder>

Transcode H.264/HEVC video clips so they are editable in the free
version of DaVinci Resolve on Linux, which cannot decode those codecs.

For every video file (.mp4, .mov, .m4v, .mkv) directly inside <folder>:
  - H.264/HEVC clips are converted to DNxHR SQ at a constant frame
    rate with PCM audio, into <folder>/resolve-transcodes/
  - clips already editable by Resolve (ProRes, MJPEG) are skipped
  - clips already converted are skipped, so re-running is safe

Original files are never modified. Point DaVinci Resolve at the
resolve-transcodes subfolder.

Options:
  -h, --help   Show this message and exit
EOF
        exit 0
        ;;
    esac

    src="''${1:?Usage: resolve-transcode <folder>}"
    src="$(readlink -f "$src")"
    out_dir="$src/resolve-transcodes"
    mkdir -p "$out_dir"
    cd "$src"

    done_n=0
    skip_n=0
    for f in *; do
      [ -f "$f" ] || continue
      case "$f" in
        *.mp4|*.MP4|*.mov|*.MOV|*.m4v|*.M4V|*.mkv|*.MKV) ;;
        *) continue ;;
      esac

      codec="$("$FFPROBE" -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 -- "$f" | head -n1 | tr -d ',')"
      case "$codec" in
        h264|hevc|h265) ;;
        *) echo "skip (already editable: $codec): $f"; skip_n=$((skip_n+1)); continue ;;
      esac

      name="''${f%.*}"
      out="$out_dir/$name.mov"
      if [ -e "$out" ]; then
        echo "skip (already transcoded): $f"
        skip_n=$((skip_n+1))
        continue
      fi

      fps="$("$FFPROBE" -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 -- "$f" | head -n1 | tr -d ',')"
      case "$fps" in
        ""|"0/0") fps="$("$FFPROBE" -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=noprint_wrappers=1:nokey=1 -- "$f" | head -n1 | tr -d ',')" ;;
      esac

      echo "transcoding ($codec @ $fps): $f"
      "$FFMPEG" -nostdin -hide_banner -loglevel error -stats -i "$f" \
        -map 0:v:0 -map 0:a? -fps_mode cfr -r "$fps" \
        -c:v dnxhd -profile:v dnxhr_sq -pix_fmt yuv422p \
        -c:a pcm_s16le -f mov "$out.tmp.mov"
      mv "$out.tmp.mov" "$out"
      done_n=$((done_n+1))
    done

    echo "done: $done_n transcoded, $skip_n skipped -> $out_dir"
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
    davinci-resolveWrapped
    ffmpeg
    resolveTranscode
  ];

  xdg.desktopEntries.davinci-resolve = {
    name = "DaVinci Resolve";
    exec = "${davinci-resolveWrapped}/bin/davinci-resolve";
    terminal = false;
    type = "Application";
    icon = "${pkgs.davinci-resolve}/share/icons/hicolor/128x128/apps/davinci-resolve.png";
    comment = "Video Editing and A/V post production software";
    categories = [ "Video" "AudioVideo" "Graphics" ];
  };

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
