{ pkgs, config, ... }:
let
  # Samsung Odyssey G7 EDID — blocks 0+1 only (256 bytes, 512 hex chars).
  #   Block 0: base EDID 1.4  (manufacturer SAM, model "Odyssey G7", serial HNTT700043)
  #   Block 1: CTA-861 extension
  #       VIC 118  3840x2160@120 Hz  (preferred for Sunshine capture)
  #       VIC  97  3840x2160@60 Hz
  #       HDR Static Metadata: SMPTE ST2084 (HDR10 PQ), max ~1015 cd/m²
  #       Colorimetry: BT.2020YCC + BT.2020RGB
  #
  # Source: the first 2 blocks of the linux-hardware.org entry SAM72C0/2022/96010477120C.
  # That entry returns 768 bytes (the 3-block EDID duplicated twice); the kernel rejects
  # the full file as "Invalid firmware EDID".  We supply only the valid portion here.
  # Extension count fixed 0x02→0x01, block-0 checksum adjusted 0x72→0x73.
  # Checksums verified by edid-decode: no errors on either block.
  virtualDisplayEdidHex =
    "00ffffffffffff004c2dc07245464c30"
    + "1d200104b54628783a4ed5ae4e45aa27"
    + "0e505425cf0081c0810081809500a9c0"
    + "b300714f010108e80030f2705a80b058"
    + "8a00b9882100001e000000fd081ea51e"
    + "759c000a202020202020000000fc004f"
    + "6479737365792047370a2020000000ff"
    + "00484e54543730303034330a20200173"
    + "020326f048615f101f3f040376230907"
    + "0783010000e305c000e60605018b5a00"
    + "e5018b849079565e00a0a0a029503020"
    + "3500b9882100001a6fc200a0a0a05550"
    + "30203500b9882100001a023a80187138"
    + "2d40582c4500b9882100001e00000000"
    + "00000000000000000000000000000000"
    + "000000000000000000000000000000bf";

  # Write the hex content to a store file so the runCommand shell script
  # never has to embed single-quote characters (which would conflict with
  # the Nix ''...'' string delimiters).
  virtualDisplayEdidHexFile = pkgs.writeText "virtualDisplay-edid.hex" virtualDisplayEdidHex;

  virtualDisplayEdidScript = pkgs.writeText "make-edid.py" ''
    import sys
    with open(sys.argv[1]) as f:
        hex_str = f.read().strip()
    with open(sys.argv[2], "wb") as f:
        f.write(bytes.fromhex(hex_str))
  '';

  virtualDisplayEdidPkg = pkgs.runCommand "samsung-g7-virtual-display-edid" { } ''
    mkdir -p $out/lib/firmware/edid
    ${pkgs.python3}/bin/python3 ${virtualDisplayEdidScript} \
      ${virtualDisplayEdidHexFile} \
      $out/lib/firmware/edid/virtualDisplay.bin
  '';
in
{
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    applications = {
      env = {
        PATH = "$(PATH):$(HOME)/.local/bin";
      };
      apps = [
        {
          name = "Steam Big Picture";
          detached = [
            "setsid steam steam://open/bigpicture"
          ];
          prep-cmd = [
            {
              do = "";
              undo = "setsid steam steam://close/bigpicture";
            }
          ];
          image-path = "steam.png";
          exclude-global-prep-cmd = "false";
          auto-detach = "true";
        }
      ];
    };
    settings = {
      sunshine_name = "athena-nixos";
      notify_pree_releases = "disabled";
      system_tray = "enabled";
      controller = "enabled";
      gamepad = "auto";
      back_button_timeout = "3000";
      stream_audio = "enabled";
      virtual_sink = "Steam Streaming Speakers";
      adapter_name = "/dev/dri/renderD128";
      output_name = "DP-1";
      max_bitrate = "0";
      address_family = "both";
      lan_encryption_mode = "0";
      wan_encrpytion_mode = "2";
      global_prep_cmd = builtins.toJSON [
        {
          # Enable virtual DP-1 at 4K@120Hz (mode matches the Samsung G7 EDID's VIC 118).
          "do" = "wlr-randr --output DP-1 --on --mode 3840x2160@120";
          "undo" = "wlr-randr --output DP-1 --off";
        }
        {
          "do" = "wlr-randr --output DP-2 --off";
          "undo" = "wlr-randr --output DP-2 --on";
        }
        {
          "do" = "wlr-randr --output HDMI-A-1 --off";
          "undo" = "wlr-randr --output HDMI-A-1 --on";
        }
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [
    47984
    47989
    47990
    48010
  ];

  users.users.foxtrot = {
    extraGroups = [ "uinput" ];
  };

  # Virtual display for headless Sunshine streaming.
  #
  # Forces DP-1 on at the kernel level using a firmware EDID so the GPU presents
  # a 4K HDR virtual output even with nothing physically connected.
  #
  # The EDID is a fixed 2-block (256-byte) slice of the Samsung Odyssey G7 EDID:
  #   • Block 0: base EDID 1.4  (manufacturer SAM, serial HNTT700043)
  #   • Block 1: CTA-861 extension
  #       – VIC 118: 3840x2160@120Hz
  #       – VIC  97: 3840x2160@60Hz
  #       – HDR Static Metadata: SMPTE ST2084 (HDR10 PQ)
  #       – Colorimetry: BT.2020YCC + BT.2020RGB
  #       – Max luminance: ~1015 cd/m²
  #
  # The original linux-hardware.org entry (SAM72C0/2022/96010477120C) returned a
  # 768-byte file that was blocks 0-2 duplicated verbatim; the kernel rejected it
  # as "Invalid firmware EDID".  We supply the corrected 256-byte binary directly
  # via hardware.display.edid.raw to avoid that fetcher.
  hardware.display.outputs."DP-1".mode = "e";
  hardware.display.outputs."DP-1".edid = "virtualDisplay.bin";

  hardware.display.edid.packages = [ virtualDisplayEdidPkg ];

  # Sunshine web UI credentials — stored as a sops secret.
  # To set/rotate: `sops secrets/secrets.yaml` and add key `sunshine/password`.
  # The --creds call re-hashes with a fresh random salt on every service start,
  # so the plain password never persists on disk.
  sops.secrets."sunshine/password" = {
    owner = config.users.users.foxtrot.name;
  };

  systemd.user.services.sunshine.serviceConfig.ExecStartPre = [
    "${pkgs.writeShellScript "sunshine-set-creds" ''
      ${config.services.sunshine.package}/bin/sunshine \
        --creds foxtrot "$(cat ${config.sops.secrets."sunshine/password".path})"
    ''}"
  ];

  environment.systemPackages = with pkgs; [
    wlr-randr
  ];
}
