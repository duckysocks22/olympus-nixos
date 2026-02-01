{ ... }:
{
  services.easyeffects = {
    enable = true;
    preset = "BaseAudio";
    extraPresets = {
      BaseAudio = {
        input = {
          blocklist = [];
          "compressor#0" = {
            "attack" = 15.0;
            "boost-amount" =  0.0;
            "boost-threshold" =  -72.0;
            "bypass" = false;
            "dry" = -80.01;
            "hpf-frequency" = 10.0;
            "hpf-mode" = "Off";
            "input-gain" = 0.0;
            "input-to-link" = 0.0;
            "input-to-sidechain" = 0.0;
            "knee" = -6.0;
            "link-to-input" = 0.0;
            "link-to-sidechain" = 0.0;
            "lpf-frequency" = 20000.0;
            "lpf-mode" = "Off";
            "makeup" = 3.0;
            "mode" = "Downward";
            "output-gain" = 0.0;
            "ratio" = 3.0;
            "release" = 200.0;
            "release-threshold" = -40.0;
            "sidechain" = {
                "lookahead" = 0.0;
                "mode" = "RMS";
                "preamp" = 0.0;
                "reactivity" = 10.0;
                "source" = "Middle";
                "stereo-split-source" = "Left/Right";
                "type" = "Feed-forward";
            };
            "sidechain-to-input" = 0.0;
            "sidechain-to-link" = 0.0;
            "stereo-split" = false;
            "threshold" = -18.0;
            "wet" = 0.0;
          };
        };
      };
    };
  };
}
