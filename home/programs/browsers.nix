{ pkgs, config, inputs, ...}:

{

  home.packages = [
  ];

  programs.firefox = {
    enable = true;
  
    profiles."default" = {
      name = "default";
      userChrome = ''
        .tab-text { font-size: 14px !important; }
      '';
      settings = {

      };
    };
  };
}
