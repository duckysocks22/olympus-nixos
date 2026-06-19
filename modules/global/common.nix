{ pkgs, inputs, ...}:
let
  dwproton = pkgs.callPackage ../packages/dwproton.nix { };
  proton-em = pkgs.callPackage ../packages/proton-em.nix { };
in
{

  imports = [
    inputs.aagl.nixosModules.default
  ];

  programs.steam = {
    enable = true;
    package = pkgs.steam.override {
      extraBwrapArgs = [ "--bind" "/dev/null" "/etc/ld-nix.so.preload" ];
    };
    extraCompatPackages = with pkgs; [
      proton-ge-bin
      dwproton
      proton-em
    ];
  };

  programs.gamescope = {
    enable = true;
    # Wrap the gamescope binary to always clear LD_PRELOAD before launch.
    # Steam preloads gameoverlayrenderer.so via LD_PRELOAD; this conflicts
    # with gamescope's Vulkan compositor and causes FPS drops after ~30 min.
    # Clearing it here means any Steam launch option using gamescope doesn't
    # need to include LD_PRELOAD="" manually. Steam Input and achievements
    # are unaffected — only the visual Steam overlay is disabled.
    package = pkgs.runCommand "gamescope-ldpreload-cleared" {
      nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    } ''
      mkdir -p $out/bin
      makeWrapper ${pkgs.gamescope}/bin/gamescope $out/bin/gamescope \
        --inherit-argv0 \
        --unset LD_PRELOAD
      ln -s ${pkgs.gamescope}/bin/gamescopectl $out/bin/gamescopectl
    '';
  };

  security.pam.loginLimits = [
    { domain = "@users"; type = "-"; item = "rtprio"; value = "99"; }
  ];

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        reaper_freq = 5;
        desiredgov = "powersave";
        desiredprof = "performance";
        igpu_desiredgov = -1; #default is powersave
        igpu_power_threshold = 0.3;
        softrealtime = "off";
        renice = 0;
        ioprio = 0;
        inhibit_screensaver = 1;
        disable_splitlock = 1;
      };
      filter = {
        #whitelist = RiseOfTheTombRaider;
        #blacklist = HalfLife3;
      };
      gpu = {
        apply_gpu_optimisations = 0; #'accept-responsibility' enables overclocking
        #gpu_device = 0
        amd_performance_level = "high";
      };
      cpu = {
        #park_cores = no;
        #pin_cores = yes;
      };
      supervisor = {
        #supervisor_whitelist = ; 
        #supervisor_blacklist = ;
      };
      custom = {

      };
    };
  };

  programs.gnupg.agent = {
    enable = true;
  };

  programs.honkers-railway-launcher.enable = true;

  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    python312Packages.yt-dlp
    bubblewrap
    (writeShellScriptBin "no-hardened" ''
      exec ${bubblewrap}/bin/bwrap \
        --dev-bind / / \
        --bind /dev/null /etc/ld-nix.so.preload \
        -- "$@"
    '')
  ];

  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override
    {
      extraPkgs = pkgs:
      [
        pkgs.icu
        pkgs.libxcrypt-legacy
        pkgs.python312
        pkgs.python312Packages.torch
      ];
    };
  };
}
