{
  _module.args.util.functions = {
    mkSimpleService =
      {
        description ? "a description",
        ExecStart,
        type ? "simple",
        user ? "root",
      }:
      {
        description = "${description}";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          ExecStart = "${ExecStart}";
          Type = "${type}";
          User = "${user}";
          Restart = "always";
        };
      };
  };
}
