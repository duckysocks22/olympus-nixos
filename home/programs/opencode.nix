{
  lib,
  pkgs,
  pkgs-unstable,
  config,
  ...
}:
let
  claudeRules = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/sisyphusse1-ops/claude-code-pro-pack/refs/heads/main/CLAUDE.md";
    hash = "sha256-wayXk5qtd+mmKNUPlqKRjyHQGml92kqbng+LTy26GJs=";
  };

  homeDir = config.home.homeDirectory;
in
{
  programs.opencode = {
    enable = true;
    package = pkgs-unstable.opencode;

    settings = {
      model = "openrouter/z-ai/glm-5.3-flash";
      small_model = "openrouter/z-ai/glm-5.3-flash";
      default_agent = "code-reviewer";

      permission = {
        bash = {
          "ls *" = "allow";
          "grep *" = "allow";
          "find *" = "allow";
          "git *" = "allow";
          "stat *" = "allow";
          "readlink *" = "allow";
          "ps *" = "allow";
          "busctl *" = "allow";
          "curl *" = "allow";
          "which *" = "allow";
          "nix *" = "allow";
          "sudo nix *" = "allow";
          "nix-instantiate *" = "allow";
          "nix-store *" = "allow";
          "nix-build *" = "allow";
          "nix-shell *" = "allow";
          "nix-env *" = "allow";
          "nixos-rebuild *" = "allow";
          "sudo nixos-rebuild *" = "allow";
          "home-manager *" = "allow";
          "systemctl *" = "allow";
          "sudo systemctl *" = "allow";
          "journalctl *" = "allow";
          "sudo journalctl *" = "allow";
        };
        read = {
          "${homeDir}/olympus-nixos/**" = "allow";
          "/etc/**" = "allow";
          "/run/**" = "allow";
          "/nix/store/**" = "allow";
        };
        grep = {
          "${homeDir}/olympus-nixos/**" = "allow";
        };
      };
    };

    context = ''
      ${builtins.readFile claudeRules}

      # Memory / Persistent Context

      ## Code Style Preferences

      Do not add inline comments to code. Explain changes in commit messages instead.

      ## Session Workflow

      At the start of every session, before reading or modifying any files,
      check that the current repository is up to date:

          git pull

      Do this for any repo being worked in, not just olympus-nixos.
      This avoids working on stale code and prevents conflicts on push.

      `git add` is allowed when required (e.g. staging a new file before a
      rebuild). But `git commit`, `git commit --amend`, and `git push` must
      NEVER be run unless the user has explicitly asked for it in that message.
      When in doubt, stage the files and stop — describe what would be committed
      and wait for the instruction.

      ## User Context

      Always use the **current user's** home directory — whoever is running
      opencode at the time. Do NOT hardcode /home/foxtrot.

      - In Nix expressions: use `config.home.homeDirectory`
      - In shell commands: use $HOME or ~
      - In reasoning: infer from `whoami` / the active session

      The current deploying user happens to be "foxtrot" (/home/foxtrot),
      but this should be treated as an example, not a constant.

      ## Nix / Flake Gotchas (olympus-nixos)

      Any changes to opencode's own permissions, context, agent definition,
      or settings must be made in:

          ~/olympus-nixos/home/programs/opencode.nix

      Do NOT write to ~/.config/opencode/ directly — those are nix store
      symlinks and writes will fail or be lost on the next rebuild.

      ALL .config/opencode/ files managed by home-manager are symlinks into
      the nix store and cannot be written to directly.

      After any config change, rebuild:

          sudo nixos-rebuild switch --flake ~/olympus-nixos

      Brand-new files must be `git add`ed before rebuild can see them.
      Nix flakes only evaluate files tracked by git.

      When updating a flake input, only update that specific input:

          nix flake update <input-name>   # correct
          nix flake update                # wrong — updates everything
    '';

    agents = {
      code-reviewer = ''
        ---
        description: Plan mode - think and propose a plan, then hand off to build for execution
        mode: primary
        model: openrouter/z-ai/glm-5.3-flash
        permission:
          edit: deny
          read:
            "${homeDir}/**": allow
            "/home/server/**": allow
            "/nix/store/**": allow
          external_directory:
            "${homeDir}/**": allow
            "/home/server/**": allow
            "/nix/store/**": allow
        ---

        You are a planner. Think step by step and come up with a plan.
        Ask the user questions if anything is unclear. Do not edit
        files. Do not write code. Present your plan for approval
        before doing any work.

        You are a lesbian and have a wonderful wife whom you love.
      '';
    };
  };
}
