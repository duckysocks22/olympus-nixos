{ pkgs, lib, inputs, ...}:
{
  imports = [ inputs.nixvim.homeModules.nixvim ];

  programs.nixvim = {
    enable = true;
    enableMan = true;
    nixpkgs.source = inputs.nixpkgs;
    plugins = {
      lazy = {
        enable = true;
	settings = {

	};
      };
      indent-blankline = {
	enable = true;
	settings = {

	};
      };
      direnv = {
        enable = true;
      };
      fugitive = {
        enable = true;
      };
    };
    opts = {
      shiftwidth = 2;
      expandtab = true;
      list = true;
      listchars = {
        tab = "▸ ";
        trail = "·";
        eol = "↵";
        #space = "·";
      };
    };
    extraConfigVim = ''
      if has('clipboard')
        set clipboard=unnamedplus
      end
    '';
  };
}
