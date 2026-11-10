{ inputs, self, ... }:
{
  flake.homeModules.fzf = {
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
}
