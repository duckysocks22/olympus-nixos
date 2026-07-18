{ pkgs, inputs, ... }:
{
  services.swayidle = 
  let
    lock = "${pkgs.inputs.noctalia.packages.x86_64.default}/bin/noctalia-shell ipc call sessionMenu lock";
    display = status: "${pkgs.niri}/bin/niri msg action power=${status}-monitors";
    toast = ''{"title": "Lock", "body": "Locking in 5 seconds", "type": "warning"}'';
  in
  {
    timeouts = [
      {
      timeout = 15; # in seconds
      command = "${pkgs.inputs.noctalia.packages.x86_64.default}/bin/noctalia-shell ipc call toast send '${toast}'";
      }
      {
        timeout = 20;
        command = "${pkgs.gamemode}/bin/gamemoded -s 2>/dev/null || ${lock}";
      }
      {
        timeout = 30;
        command = "${pkgs.gamemode}/bin/gamemoded -s 2>/dev/null || ${display "off"}";
        resumeCommand = display "on";
      }
      {
        timeout = 60;
        command = "${pkgs.gamemode}/bin/gamemoded -s 2>/dev/null || ${pkgs.systemd}/bin/systemd-inhibit --list | ${pkgs.gnugrep}/bin/grep -q 'sleep.*block' || ${pkgs.systemd}/bin/systemctl suspend";
      }
    ];
    events = [
      {
        event = "before-sleep";
        # adding duplicated entries for the same event may not work
        command = (display "off") + "; " + lock;
      }
      {
        event = "after-resume";
        command = display "on";
      }
      {
        event = "lock";
        command = (display "off") + "; " + lock;
      }
      {
        event = "unlock";
        command = display "on";
      }
    ];
  };
}
