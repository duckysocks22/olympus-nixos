{ inputs, self, ... }:
{
  flake.homeModules.fzf = {
    programs.fzf = {
      enable = true;
      enableFishIntegration = true;

      defaultOptions = [
        "--ansi"
        "--bind=tab:down,btab:up,change:top,ctrl-space:toggle"
        "--border=rounded"
        "--cycle"
        "--ignore-case"
        "--info=hidden"
        "--layout=reverse"
        "--multi"
        "--tiebreak=begin"
      ];
    };
  };
}
