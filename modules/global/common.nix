{ pkgs, inputs, ... }:
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
      extraBwrapArgs = [
        "--bind"
        "/dev/null"
        "/etc/ld-nix.so.preload"
      ];
    };
    extraCompatPackages = with pkgs; [
      proton-ge-bin
      dwproton
      proton-em
    ];
  };

  programs.gamescope = {
    enable = true;
  };

  security.pam.loginLimits = [
    {
      domain = "@users";
      type = "-";
      item = "rtprio";
      value = "99";
    }
  ];

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        reaper_freq = 5;
        desiredgov = "powersave";
        desiredprof = "performance";
        igpu_desiredgov = -1; # default is powersave
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
        apply_gpu_optimisations = 0; # 'accept-responsibility' enables overclocking
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

  environment.systemPackages =
    (with pkgs; [
      python312Packages.yt-dlp
      unzip
      bubblewrap
      (writeShellScriptBin "no-hardened" ''
        exec ${bubblewrap}/bin/bwrap \
          --dev-bind / / \
          --bind /dev/null /etc/ld-nix.so.preload \
          -- "$@"
      '')
    ])
    ++ (with inputs.reshade.packages.${pkgs.system}; [
      reshade
      reshade-shaders-full
    ]);

  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override {
      extraPkgs = pkgs: [
        pkgs.icu
        pkgs.libxcrypt-legacy
        pkgs.python312
      ];
    };
  };
}
