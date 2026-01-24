{ pkgs, ...}:
{
  programs.git = {
    enable = true;
    settings = {
     user.Name = "foxtrottt";
     user.Email = "dawn.spinal795@passmail.net";
    };
  };
}
