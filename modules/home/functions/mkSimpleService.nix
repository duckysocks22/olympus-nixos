{ inputs, self, ... }:
{
  flake.homeModules.mkSimpleService =
    {
      lib,
      ...
    }:
    {
      lib.functions.mkSimpleService = name: ExecStart: {
        ${name} = {
          Unit = {
            Description = "${name}";
            After = [ "graphical.target" ];
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
          Service = {
            inherit ExecStart;
            Restart = "on-failure";
            RestartSec = 5;
            Type = "simple";
          };
        };
      };
    };
}
