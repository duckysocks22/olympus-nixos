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
    extraCompatPackages = with pkgs; [
      proton-ge-bin
      dwproton
      proton-em
    ];
  };

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        reaper_freq = 5;
        desiredgov = "performance";
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

  programs.honkers-railway-launcher.enable = true;

  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    python312Packages.yt-dlp
  ];
}
