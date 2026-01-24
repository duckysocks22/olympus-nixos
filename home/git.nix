{ pkgs, ...}:
{
  programs.git = {
    enable = true;
    settings = {
     user.name = "foxtrottt";
     user.email = "dawn.spinal795@passmail.net";
    };
  };
}
