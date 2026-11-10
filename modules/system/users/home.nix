{ inputs, self, ... }:
{
  flake.nixosModules.homeManagerCommon =
    {
      inputs,
      ...
    }:
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = {
          inherit inputs;
          pkgs-unstable = import inputs.nixpkgs-unstable {
            localSystem = "x86_64-linux";
            config.allowUnfree = true;
          };
        };
      };
    };

  flake.homeModules.homeCommon =
    {
      config,
      ...
    }:
    let
      mkSessionVariables = config: {
        EDITOR = "nvim";
        VISUAL = "nvim";
        SCREENDIR = "${config.xdg.dataHome}/screen";
        _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.dataHome}/java";
        XDG_CONFIG_HOME = config.xdg.configHome;
        XDG_CACHE_HOME = config.xdg.cacheHome;
        XDG_DATA_HOME = config.xdg.dataHome;
        XDG_STATE_HOME = config.xdg.stateHome;
      };
    in
    {
      home.sessionVariables = mkSessionVariables config;
    };
}
