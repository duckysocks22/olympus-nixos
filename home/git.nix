{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    ignores = [ "result" ".direnv" ".claude/settings.local.json" ];
    settings = {
      push = { autoSetupRemote = true; };
      pull = { rebase = false; };
      init = { defaultBranch = "main"; };
      commit = { gpgSign = true; };
      user = {
        name = "foxtrottt";
        email = "code@olympus.moe";
      };
      credential = {
        "https://dawn.wine" = {
          helper = "oauth";
        };
        helper = "libsecret";
      };
    };
    signing = {
      format = "ssh";
      key = "~/.ssh/id_ed25519.pub";
      signByDefault = true;
    };
  };
}
