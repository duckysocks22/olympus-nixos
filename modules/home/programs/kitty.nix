{ inputs, self, ... }:
{
  flake.homeModules.kitty =
    {
      config,
      pkgs,
      ...
    }:
    let
      h = config.lib.stylix.colors.withHashtag;
    in
    {
      programs.kitty = {
        extraConfig =
          let
            digits = "0123456789abcdef";
            parseHex = s: (builtins.fromTOML "v = 0x${builtins.substring 1 6 s}").v;
            nibble = n: builtins.substring n 1 digits;
            toHex2 =
              v:
              let
                x = builtins.floor (v + 0.5);
                hi = builtins.div x 16;
                lo = x - hi * 16;
              in
              "${nibble hi}${nibble lo}";
            tonalMix =
              hex: t:
              let
                c = parseHex hex;
                b = parseHex h.base00;
                cr = builtins.div c 65536;
                ct = c - cr * 65536;
                cg = builtins.div ct 256;
                cb = ct - cg * 256;
                br = builtins.div b 65536;
                bt = b - br * 65536;
                bg = builtins.div bt 256;
                bb = bt - bg * 256;
                blend = x: y: toHex2 (x * (1 - t) + y * t);
              in
              "#${blend cr br}${blend cg bg}${blend cb bb}";
            tone = hex: tonalMix hex 0.3;
          in
          ''
            color1 ${tone h.red}
            color2 ${tone h.green}
            color3 ${tone h.yellow}
            color4 ${tone h.blue}
            color6 ${tone h.cyan}
            color9 ${tone h.red}
            color10 ${tone h.green}
            color11 ${tone h.yellow}
            color12 ${tone h.blue}
            color14 ${tone h.cyan}
            color16 ${tone h.orange}
            color17 ${tone h.brown}
          '';
      };
    };
}
