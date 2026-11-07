{ inputs, self, ... }:
{
  flake.homeModules.git =
    {
      pkgs,
      ...
    }:
    {
      programs.git = {
        enable = true;
        ignores = [
          "result"
          ".direnv"
          ".claude"
        ];
        settings = {
          push = {
            autoSetupRemote = true;
          };
          pull = {
            rebase = false;
          };
          init = {
            defaultBranch = "main";
          };
          commit = {
            gpgSign = true;
          };
          gpg = {
            format = "ssh";
          };
          user = {
            name = "foxtrottt";
            email = "code@olympus.moe";
            signingKey = "~/.ssh/id_ed25519.pub";
          };
          credential = {
            "https://dawn.wine" = {
              helper = "oauth";
            };
            helper = "libsecret";
          };
        };
      };
    };
}
