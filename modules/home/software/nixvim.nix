{ inputs, self, ... }:
{
  flake.homeModules.nixvim =
    {
      inputs,
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [ inputs.nixvim.homeModules.nixvim ];

      programs.nixvim = {
        enable = true;
        enableMan = false;
        nixpkgs.source = inputs.nixpkgs;

        plugins.lsp = {
          enable = true;
          servers.qmlls.enable = true;
        };

        plugins.treesitter = {
          enable = true;
          grammarPackages = [ pkgs.vimPlugins.nvim-treesitter.builtGrammars.qmljs ];
        };

        plugins = {
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

          cmp = {
            enable = true;
            settings = {
              sources = [ { name = "nvim_lsp"; } ];
              mapping = { };
            };
          };

          telescope.enable = true;
          nvim-tree.enable = true;
          gitsigns.enable = true;
          trouble.enable = true;
          web-devicons.enable = true;
          nvim-autopairs.enable = true;
          nvim-surround.enable = true;
          lastplace.enable = true;

          harpoon = {
            enable = true;
            enableTelescope = true;
            package = pkgs.vimPlugins.harpoon2.overrideAttrs (old: {
              postPatch = (old.postPatch or "") + ''
                sed -i 's/self\.items\[i\] = nil/table.remove(self.items, i); self._length = self._length - 1/' lua/harpoon/list.lua
                sed -i 's/if list\[idx\]\.value ~= "" then/if list[idx] ~= nil and list[idx].value ~= "" then/' lua/telescope/_extensions/marks.lua
                grep -q 'table.remove(self.items, i)' lua/harpoon/list.lua
                grep -q 'list\[idx\] ~= nil' lua/telescope/_extensions/marks.lua
              '';
            });
          };

          render-markdown.enable = true;
          lualine.enable = true;
          rainbow-delimiters.enable = true;
          illuminate.enable = true;
          todo-comments.enable = true;
          fidget.enable = true;
        };

        extraConfigLua = ''
          local _at = vim.uv.new_timer()
          _at:start(1000, 2000, vim.schedule_wrap(function()
            vim.cmd("checktime")
          end))

          local ok_t, telescope = pcall(require, "telescope")
          if ok_t and pcall(telescope.load_extension, "harpoon") then
            local raw_marks = telescope.extensions.harpoon.marks
            telescope.extensions.harpoon.marks = function(opts)
              opts = opts or {}
              opts.prompt_title = opts.prompt_title
                or "harpoon ─ <enter> jump · <Ctrl-d> delete · <Ctrl-p>/<Ctrl-n> reorder"
              raw_marks(opts)
            end
          end

          function _G.HARPOON_SEGMENT()
            local ok, h = pcall(require, "harpoon")
            if not ok then return "" end
            local list = h:list()
            local n = list:length()
            if n == 0 then return "" end
            local _, idx = list:get_by_value(vim.api.nvim_buf_get_name(0))
            if idx then
              return string.format("⚓ %d pins · #%d", n, idx)
            end
            return string.format("⚓ %d pins", n)
          end
        '';

        opts = {
          autoread = true;
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

        autoCmd = [
          {
            event = [
              "FocusGained"
              "CursorHold"
              "CursorHoldI"
            ];
            pattern = [ "*" ];
            command = "checktime";
          }
          {
            event = [
              "BufEnter"
              "BufWritePost"
            ];
            pattern = [ "*" ];
            group = "harpoon-lualine-refresh";
            command = "redrawstatus";
          }
        ];

        keymaps = [
          {
            mode = "n";
            key = "<leader>ha";
            action.__raw = ''
              function()
                local list = require("harpoon"):list()
                local name = vim.api.nvim_buf_get_name(0)
                local _, idx = list:get_by_value(name)
                if idx then
                  vim.notify("[harpoon] already pinned as #" .. idx)
                  return
                end
                list:add()
                vim.notify("[harpoon] pinned " .. vim.fn.fnamemodify(name, ":t") .. " (#" .. list:length() .. ")")
                vim.cmd("redrawstatus")
              end
            '';
            options.desc = "Harpoon: pin current file";
          }
          {
            mode = "n";
            key = "<leader>hd";
            action.__raw = ''
              function()
                local list = require("harpoon"):list()
                local name = vim.api.nvim_buf_get_name(0)
                local _, idx = list:get_by_value(name)
                if idx == nil then
                  vim.notify("[harpoon] not pinned: " .. vim.fn.fnamemodify(name, ":t"))
                  return
                end
                list:remove()
                vim.notify("[harpoon] unpinned " .. vim.fn.fnamemodify(name, ":t"))
                vim.cmd("redrawstatus")
              end
            '';
            options.desc = "Harpoon: unpin current file";
          }
          {
            mode = "n";
            key = "<leader>hp";
            action.__raw = ''
              function()
                require("telescope").extensions.harpoon.marks()
              end
            '';
            options.desc = "Harpoon: marks picker";
          }
        ];

        autoGroups = {
          harpoon-lualine-refresh = {
            clear = true;
          };
        };

        plugins.lualine.settings = {
          sections = {
            lualine_z = [
              { __raw = "function() return _G.HARPOON_SEGMENT() end"; }
              "location"
            ];
          };
        };
      };
    };
}
