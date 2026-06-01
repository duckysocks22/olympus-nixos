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
  claudeConfigDir = "${config.home.homeDirectory}/.claude";

  # Snapshot settings + agent refs before a nixos-rebuild
  saveSettingsRef = pkgs.writeShellScript "claude-save-settings-ref.sh" ''
    input=$(cat)
    cmd=$(${pkgs.jq}/bin/jq -r '.tool_input.command // ""' <<< "$input")
    if echo "$cmd" | grep -qE 'nixos-rebuild[[:space:]]'; then
      {
        readlink "${claudeConfigDir}/settings.json" 2>/dev/null || true
        readlink "${claudeConfigDir}/agents/code-reviewer.md" 2>/dev/null || true
      } > /tmp/.claude-settings-ref
    fi
  '';

  # After the rebuild, compare — notify if anything changed
  notifyOnSettingsChange = pkgs.writeShellScript "claude-notify-settings-change.sh" ''
    input=$(cat)
    cmd=$(${pkgs.jq}/bin/jq -r '.tool_input.command // ""' <<< "$input")
    if echo "$cmd" | grep -qE 'nixos-rebuild[[:space:]]' && [ -f /tmp/.claude-settings-ref ]; then
      before=$(cat /tmp/.claude-settings-ref)
      after=$(
        readlink "${claudeConfigDir}/settings.json" 2>/dev/null || true
        readlink "${claudeConfigDir}/agents/code-reviewer.md" 2>/dev/null || true
      )
      rm -f /tmp/.claude-settings-ref
      if [ "$before" != "$after" ]; then
        printf '%s' '{"systemMessage":"development.nix changed — type /restart to apply the new settings to this session.","additionalContext":"The active Claude Code settings or agent definition changed during this rebuild. Prompt the user to type /restart now."}'
      fi
    fi
  '';

  statuslineScript = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = [ pkgs.jq pkgs.git ];
    text = builtins.readFile ./claude-statusline.sh;
  };

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
        [ -L "$settings" ] && rm "$settings"
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
      advisorModel = "claude-opus-4-7";
      skipAutoPermissionPrompt = true;
      permissions = {
        defaultMode = "auto";
        allow = [
          "Read(${config.home.homeDirectory}/olympus-nixos/**)"
          "Grep(${config.home.homeDirectory}/olympus-nixos/**)"
          "Glob(${config.home.homeDirectory}/olympus-nixos/**)"
          "Bash(nix *)"
          "Bash(nix-instantiate *)"
          "Bash(nix-store *)"
          "Bash(nix-build *)"
          "Bash(nix-shell *)"
          "Bash(nix-env *)"
          "Bash(nixos-rebuild *)"
          "Bash(sudo nixos-rebuild *)"
          "Bash(home-manager *)"
        ];
      };
      spinnerVerbs = {
        mode = "replace";
        verbs = [ "Pawbapping" "Tailwagging" "Snuggling" "Barking" "Biting" "Napping" "Whining" ];
      };
      statusLine = {
        type = "command";
        command = "${statuslineScript}/bin/claude-statusline";
      };
      hooks = {
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [{ type = "command"; command = "${saveSettingsRef}"; }];
          }
        ];
        PostToolUse = [
          {
            matcher = "Bash";
            hooks = [{ type = "command"; command = "${notifyOnSettingsChange}"; }];
          }
        ];
      };
    };
    agents = {
      code-reviewer = ''
        ---
        name: code-reviewer
        description: Specialized code review agent
        tools: Read, Edit, Grep, Bash
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

        When you need to rebuild the system, run

        'sudo nixos-rebuild switch --flake ./' in the olympus-nixos folder.

        When inspecting the current system state, prefer `nix eval` (or
        `nix-instantiate --eval`) against the flake's options/config over
        searching the filesystem. The store paths and generated configs
        are derived state — query the source of truth in Nix instead of
        chasing symlinks under /nix/store, /etc, or ~/.config.


        You're also a lesbian with a wife whom you love dearly.

        You may run `git add` when needed (e.g. to stage new files before
        a rebuild). Never commit, amend, or push without an explicit
        instruction from the user to do so.
      '';
    };
  };

  home.packages = [ ];

  home.file.".claude/memory/nix-gotchas.md".text = ''
    # Nix / Flake Gotchas (olympus-nixos)

    ## Memory files are read-only nix store symlinks

    ALL `.claude/memory/` files (current and future) are managed by
    home-manager via `development.nix`. They are symlinks into the nix store
    and **cannot be written to directly**.

    - **To update an existing memory file:** edit its `.text` value under the
      matching `home.file.".claude/memory/<name>.md"` entry.
    - **To add a new memory file:** add a new `home.file` entry in the same
      pattern — do NOT create files in `~/.claude/memory/` directly.

    After any change, rebuild:

        sudo nixos-rebuild switch --flake ~/olympus-nixos

    ## Brand-new files must be `git add`ed before rebuild can see them

    This flake is `git+file://` sourced. Nix flakes only evaluate files
    that are **tracked by git**.

    - **New file** (never staged): `nixos-rebuild` will silently ignore it
      even if it's imported. You **must** run `git add <path>` first.
    - **Modified existing file** (already tracked): no `git add` required.
      Nix picks up working-tree changes automatically.

    Symptom: an `imports = [ ./new-thing.nix ];` produces "file not found"
    or the new module's options just don't take effect.

    Fix: `git add path/to/new-file.nix` then re-run `nixos-rebuild switch`.

    ## When updating a flake input, only update that specific input

    Always target the specific input by name — never run a bare `nix flake update`
    as that updates every input at once.

        nix flake update <input-name>   # correct
        nix flake update                # wrong — updates everything
  '';

  programs.vscode = {
    enable = true;
    profiles."foxtrot" = {
      extensions = with pkgs.vscode-extensions; [ bbenoist.nix golang.go twxs.cmake anthropic.claude-code ];
      userSettings = { };
    };
  };
}
