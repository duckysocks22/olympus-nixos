{ inputs, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "foxtrottt";
        email = "dawn.spinal795@passmail.net";
      };
    };
  };
}
