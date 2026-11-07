{ inputs, self, ... }:
let
  homeManagerCommon = {
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
  flake.nixosModules.deck =
    {
      inputs,
      pkgs,
      config,
      ...
    }:
    {
      imports = [
        inputs.home-manager-unstable.nixosModules.home-manager
        inputs.self.nixosModules.userWarnPatch
      ];

      users.users.deck = {
        isNormalUser = true;
        home = "/home/deck";
        hashedPasswordFile = config.sops.secrets."users/deck".path;
        initialHashedPassword = "$y$j9T$EOxAFD9l0qIXDVJ1XGG7P0$OhvzNuUJXJB2TWRShPxz6Z6KkpMQvB2dqnOETQHQae5";
        extraGroups = [
          "audio"
          "input"
          "networkmanager"
          "wheel"
        ];
        shell = pkgs.fish;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcAXHlW7WhNVvoU5H6q7BZDu09Tnd60P8QDJVhpbSiJ foxtrot@circe-nixos"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJyzVQusZn11jF8/TqiSWBd+TbPxgKZIM2GK+jvZ7aCN foxtrot@athena-nixos"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDv/PuSaDn5Dg+1Bghk9OfR52iIFf5TvCucODDZKrCcx server@nixos"
        ];
      };

      programs.fish.enable = true;

      home-manager = homeManagerCommon // {
        extraSpecialArgs = {
          inputs = inputs // {
            nixpkgs = inputs.nixpkgs-unstable;
            nixvim = inputs.nixvim-unstable;
          };
          pkgs-unstable = import inputs.nixpkgs-unstable {
            localSystem = "x86_64-linux";
            config.allowUnfree = true;
          };
        };

        users.deck =
          { config, ... }:
          {
            imports = [
              inputs.self.homeModules.functions
              inputs.self.homeModules.librewolf
              inputs.self.homeModules.launchers
              inputs.self.homeModules.nixvim
              inputs.self.homeModules.baseShell
              inputs.self.homeModules.direnv
              inputs.self.homeModules.fastfetch
              inputs.self.homeModules.fzf
              inputs.self.homeModules.ranger
              inputs.self.homeModules.ssh
              inputs.self.homeModules.common
              inputs.self.homeModules.piAgent
              inputs.self.homeModules.deckSops
              inputs.self.homeModules.syncthing
            ];

            # Atuin owns Ctrl-R; fzf's fish integration would shadow it.

            home.file = {
              ".local/bin/com.discordapp.Discord" = {
                # Mute all of Discord's output by routing it into a null sink.
                source =
                  let
                    pactl = pkgs.lib.getExe' pkgs.pulseaudio "pactl";
                  in
                  pkgs.writeShellScript "com.discordapp.Discord" ''
                    unset LD_LIBRARY_PATH
                    unset LD_PRELOAD
                    if ! ${pactl} list short sinks | grep -q discord-muted; then
                      ${pactl} load-module module-null-sink sink_name=discord-muted sink_properties=device.description=Discord-Muted
                    fi
                    export PULSE_SINK=discord-muted
                    exec ${pkgs.discord}/bin/discord "$@"
                  '';
                force = true;
              };
              ".local/share/applications/com.discordapp.Discord.desktop" = {
                source = pkgs.writeText "com.discordapp.Discord.desktop" ''
                  [Desktop Entry]
                  Name=Discord
                  Comment=All-in-one voice and text chat for gamers
                  Exec=${config.home.homeDirectory}/.local/bin/com.discordapp.Discord
                  Icon=discord
                  Terminal=false
                  Type=Application
                  Categories=Network;InstantMessaging;
                '';
                force = true;
              };
            };

            systemd.user.services.discord-autostart = {
              Unit = {
                Description = "Discord (background) for Steam Big Picture";
                After = [ "gamescope-session.service" ];
                PartOf = [ "graphical-session.target" ];
              };
              Service = {
                Type = "exec";
                EnvironmentFile = "-%t/gamescope-environment";
                # %t/gamescope-environment outlives the session it describes, so a desktop
                # session would otherwise start Discord against a display that is gone.
                ExecCondition = "${pkgs.runtimeShell} -c 'grep -qx XDG_CURRENT_DESKTOP=gamescope %t/gamescope-environment'";
                # A crashed Discord leaves its IPC socket behind and the Decky plugin then
                # connects to the dead file and reports a refused connection instead of
                # waiting for Discord to come back.
                ExecStartPre = "${pkgs.runtimeShell} -c 'rm -f %t/discord-ipc-*'";
                ExecStart = "${config.home.homeDirectory}/.local/bin/com.discordapp.Discord";
                ExecStopPost = "${pkgs.runtimeShell} -c 'rm -f %t/discord-ipc-*'";
                Restart = "on-failure";
                RestartSec = 10;
              };
              Install.WantedBy = [ "graphical-session.target" ];
            };

            home = {
              username = "deck";
              homeDirectory = "/home/deck";
              stateVersion = "26.05";
              sessionVariables = mkSessionVariables config;
            };

            systemd.user.startServices = "sd-switch";
          };
      };
    };
}
