{ self, inputs, ... }: {

  flake.homeModules.doors = { inputs, ... }: {
    imports = [ inputs.doors.homeModules.doors ];

    programs.doors = {
      enable = true;
      settings = {
        outputs = {
          "eDP-1" = {
            enable = true;
          };
        };
      };
    };
  };

}
