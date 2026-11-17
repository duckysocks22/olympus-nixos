{ inputs, self, ... }:
{
  flake.homeModules.fastfetch =
    {
      ...
    }:
    let
      gray = builtins.fromJSON ''"\u001b[90m"'';
    in
    {
      programs.fastfetch = {
        enable = true;

        settings = {
          "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
          logo = {
            type = "file";
            source = "~/.config/fastfetch/ascii.txt";
            color = {
              "1" = "#B84F8E";
              "2" = "#EB8034";
            };
            height = 15;
            width = 8;
            padding = {
              top = 5;
              left = 3;
            };
          };
          modules = [
            "break"
            {
              type = "custom";
              format = "${gray}┌─────────────i ─────────Hardware──────────────────────┐";
            }
            {
              type = "host";
              key = " PC";
              keyColor = "green";
            }
            {
              type = "cpu";
              key = "│ ├";
              keyColor = "green";
            }
            {
              type = "gpu";
              key = "│ ├󰍛";
              keyColor = "green";
            }
            {
              type = "memory";
              key = "│ ├󰍛";
              keyColor = "green";
            }
            {
              type = "disk";
              key = "└ └";
              keyColor = "green";
            }
            {
              type = "custom";
              format = "${gray}└────────────────────────────────────────────────────┘";
            }
            "break"
            {
              type = "custom";
              format = "${gray}┌──────────────────────Software──────────────────────┐";
            }
            {
              type = "os";
              key = " OS";
              keyColor = "yellow";
            }
            {
              type = "kernel";
              key = "│ ├";
              keyColor = "yellow";
            }
            {
              type = "bios";
              key = "│ ├";
              keyColor = "yellow";
            }
            {
              type = "packages";
              key = "│ ├󰏖";
              keyColor = "yellow";
            }
            {
              type = "shell";
              key = "└ └";
              keyColor = "yellow";
            }
            "break"
            {
              type = "de";
              key = " DE";
              keyColor = "blue";
            }
            {
              type = "lm";
              key = "│ ├";
              keyColor = "blue";
            }
            {
              type = "wm";
              key = "│ ├";
              keyColor = "blue";
            }
            {
              type = "wmtheme";
              key = "│ ├󰉼";
              keyColor = "blue";
            }
            {
              type = "terminal";
              key = "└ └";
              keyColor = "blue";
            }
            {
              type = "custom";
              format = "${gray}└────────────────────────────────────────────────────┘";
            }
            "break"
            {
              type = "custom";
              format = "${gray}┌────────────────────Uptime / Age / DT────────────────────┐";
            }
            {
              type = "command";
              key = "  OS Age ";
              keyColor = "magenta";
              text = "birth_install=$(stat -c %W /persistent); current=$(date +%s); time_progression=$((current - birth_install)); days_difference=$((time_progression / 86400)); echo $days_difference days";
            }
            {
              type = "uptime";
              key = "  Uptime ";
              keyColor = "magenta";
            }
            {
              type = "datetime";
              key = "  DateTime ";
              keyColor = "magenta";
            }
            {
              type = "custom";
              format = "${gray}└─────────────────────────────────────────────────────────┘";
            }
            {
              type = "colors";
              paddingLeft = 2;
              symbol = "circle";
            }
          ];
        };
      };
    };
}
