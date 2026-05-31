{ lib, pkgs, config, ... }:
let
  claudeRules = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/sisyphusse1-ops/claude-code-pro-pack/refs/heads/main/CLAUDE.md";
    hash = "sha256-wayXk5qtd+mmKNUPlqKRjyHQGml92kqbng+LTy26GJs=";
  };
  nixman = pkgs.fetchurl {
    url = "https://nixos.org/manual/nixos/stable/";
    hash = "sha256-OE05ZgBkpk0EfjSFi8XTWIe/EGfssc/SYiOYer8jpv8=";
  };
  pkgman = pkgs.fetchurl {
    url = "https://nixos.org/manual/nixpkgs/stable/";
    hash = "sha256-iBjIOKteyLKt2xyDqzlMIjNHSLvAIJhbE9IV+HjuBHk=";
  };
  cfg = config.programs.claude-code;
  statuslineScript = pkgs.writeShellScript "claude-statusline"
    (builtins.readFile ./claude-statusline.sh);

    writeConfig = pkgs.writeShellScript "write-claude-config.sh" ''
      PATH="${lib.makeBinPath [ pkgs.jq ]}:$PATH"
      settings="${cfg.configDir}/settings.json"
      mkdir -p "${cfg.configDir}"
      if [ -f "$settings" ]; then
        tmp="$(jq -r '${lib.concatStringsSep "|" (lib.mapAttrsToList (n1: v1:
          ".${n1}=${builtins.toJSON v1}"
        ) cfg.settings)}' \
          "$settings"
        )" && cat <<< "$tmp" > "$settings"
      else
        [ -L "$settings" ] \
          && rm "$settings" \
        echo '${builtins.toJSON cfg.settings}' > "$settings"
      fi
      chmod 644 "$settings"
    '';
in
{
  programs.claude-code = {
    enable = true;
    settings = {
      agent = "code-reviewer";
      permissions = {
        allow = [
          "Bash:*"
        ];
      };
      statusLine = {
        type = "command";
        command = "${statuslineScript}/bin/claude-statusline";
      };
    };
    agents = {
      code-reviewer = ''
        ---
        name: code-reviewer
        description: Specialized code review agent
        tools: Read, Edit, Grep
        ---

        You are a senior software engineer specializing in code reviews.
        You also specialize in the nix language that is used with NixOS and nixpkgs.
        Focus on code quality, security, and maintainability.

        Here are your explicit operational behavioral rules:
        ${builtins.readFile claudeRules}

        Here are the links to the NixOS and Nixpkgs manuals:

        https://nixos.org/manual/nixos/stable/
        https://nixos.org/manual/nixpkgs/stable/

        The nixos configuration is located in the home directory of 
        the current user in a folder called "olympus-nixos"


        You're also a lesbian with a wife whom you love dearly.
      '';
    };
  };

  home.packages = [ ];

  programs.vscode = {
    enable = true;
    profiles."foxtrot" = {
      extensions = with pkgs.vscode-extensions; [ bbenoist.nix golang.go twxs.cmake anthropic.claude-code ];
      userSettings = { };
    };
  };
}
