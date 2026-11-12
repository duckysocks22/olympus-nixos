{ inputs, ... }:
{
  flake.nixosModules.deck =
    {
      inputs,
      config,
      pkgs,
      ...
    }:
    let
      nixosConfig = config;
    in
    {
      imports = [
        inputs.home-manager-unstable.nixosModules.home-manager
        inputs.self.nixosModules.homeManagerCommon
      ];

      users.users.deck = {
        isNormalUser = true;
        home = "/home/deck";
        hashedPasswordFile = config.sops.secrets."users/deck".path;

        shell = pkgs.fish;

        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcAXHlW7WhNVvoU5H6q7BZDu09Tnd60P8QDJVhpbSiJ foxtrot@circe-nixos"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJyzVQusZn11jF8/TqiSWBd+TbPxgKZIM2GK+jvZ7aCN foxtrot@athena-nixos"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDv/PuSaDn5Dg+1Bghk9OfR52iIFf5TvCucODDZKrCcx server@nyx-nixos"
        ];

        extraGroups = [
          "audio"
          "cdrom"
          "dailout"
          "input"
          "networkmanager"
          "wheel"
        ];
      };

      programs.fish.enable = true;

      home-manager.users.deck =
        {
          config,
          ...
        }:
        {
          imports = [
            # Shared home settings
            inputs.self.homeModules.homeCommon

            # Functions
            inputs.self.homeModules.functions

            # Interface
            inputs.self.homeModules.niri

            # Shell
            inputs.self.homeModules.shell

            # Software
            inputs.self.homeModules.foxtrotSops
            inputs.self.homeModules.software
            inputs.self.homeModules.launchers
            inputs.self.homeModules.social
            inputs.self.homeModules.creation
            inputs.self.homeModules.player
            inputs.self.homeModules.librewolf
            inputs.self.homeModules.nixvim
            inputs.self.homeModules.piAgent
            inputs.self.homeModules.syncthing

          ];

          home = {
            username = "deck";
            homeDirectory = nixosConfig.users.users.deck.home;
            stateVersion = nixosConfig.system.stateVersion;
          };

          systemd.user.startServices = "sd-switch";

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
        };
    };
}
