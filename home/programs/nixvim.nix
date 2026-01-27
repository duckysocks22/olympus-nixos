{ pkgs, lib, inputs, ...}:
{
  imports = [ inputs.nixvim.homeModules.nixvim ];

  programs.nixvim = {
    enable = true;
    enableMan = true;
    plugins = {
      lazy = {
        enable = true;
	settings = {

	};
      };
    };
    opts = {
      shiftwidth = 2;
      list = true;
      listchars = {
        tab = "▸ ";
        trail = "·";
        eol = "↵";
        space = "·";
      };
    };
  };
}
