{ inputs, self, ... }:
{
  flake.nixosModules.ntfy =
    {
      ...
    }:
    {
      services.ntfy-sh = {
        enable = true;
        settings = {
          base-url = "https://ntfy.olympus.moe";
          listen-http = ":1147";
          auth-default-access = "deny-all";
        };
      };
    };
}
