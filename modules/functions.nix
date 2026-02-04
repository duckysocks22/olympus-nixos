{
  _module.args.util.functions = {
    mkSimpleService = {
      description ? "a description",
      ExecStart,
      user ? "root"
    }: {
        description = "${description}";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          ExecStart = "${ExecStart}";
          Type = "simple";
          User = "${user}";
          Restart = "always";
      };
    };
  };
}
