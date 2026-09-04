{
  util,
  pkgs,
  lib,
  ...
}:
{
  systemd.services.hibernateOnLowBattery = util.functions.mkSimpleService {
    description = "Trigger hibernation on low battery";
    ExecStart = pkgs.writeShellScript "hibernateOnLowBattery" ''
      BATTSTATE="/sys/class/power_supply/BAT0/status"
      BATT="/sys/class/power_supply/BAT0/capacity"

      if [ ! -e $BATT -o ! -e $BATTSTATE ]; then # this script assumes that the battery will not be changed during the execution of this script
      	echo "Battery is not accessible"
      	exit 1
      fi

      while true; do
      	if [ "$(cat $BATTSTATE)" = "Discharging" ]; then
      		if [ $(cat $BATT) -le 5 ]; then
      			systemctl hibernate
      		fi
              fi
      	sleep 1m
      done
    '';
    user = "root";
  };
}
