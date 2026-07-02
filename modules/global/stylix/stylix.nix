{ inputs, pkgs, stylix, ... }:
{
  imports = [ inputs.stylix.nixosModules.stylix ];

  # Workaround for stylix PR #2337 (merged 2026-06-04) which references
  # services.kmscon.config — an option that has never existed in nixpkgs.
  # Remove once stylix fixes the kmscon module upstream.
  disabledModules = [ "${inputs.stylix}/modules/kmscon/nixos.nix" ];

  stylix.enable = true;
  stylix.polarity = "dark";

  stylix.autoEnable = false;
  stylix.targets.gtk.enable = true;
  
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/paraiso.yaml";
  stylix.fonts = {
    serif = {
      package = pkgs.cascadia-code;
      name = "Cascaida Code";
    };

    sansSerif = {
      package = pkgs.cascadia-code;
      name = "Cascaida Code";
    };

    monospace = {
      package = pkgs.nerd-fonts.jetbrains-mono;
      name = "JetBrains Mono";
    };

    emoji = {
      package = pkgs.noto-fonts-color-emoji;
      name = "Noto Color Emoji";
    };
    sizes.applications = 10;
  };

}
