{ inputs, self, ... }:
{
  flake.nixosModules.powerLogging = { pkgs, ... }: {
    systemd.services.power-logging = {
      description = "Log CPU (RAPL) and GPU power draw to CSV";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-modules-load.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.writeShellScriptBin "power-logging" ''
          INTERVAL=60
          RAPL=/sys/class/powercap/intel-rapl:0/energy_uj
          STATE_DIR="''${STATE_DIRECTORY:-/var/lib/power-logging}"
          OUT="$STATE_DIR/power.csv"

          if [ ! -e "$RAPL" ]; then
            echo "power-logging: no RAPL energy counter found, not logging"
            exit 0
          fi

          if [ ! -f "$OUT" ]; then
            echo "timestamp,cpu_w,gpu_w" > "$OUT"
          fi

          prev=$(cat "$RAPL")
          while sleep "$INTERVAL"; do
            cur=$(cat "$RAPL")
            delta=$((cur - prev))
            if [ "$delta" -lt 0 ]; then
              delta=$((delta + 4294967296))
            fi
            prev=$cur

            mw=$((delta / INTERVAL / 1000))
            cpu_w="$((mw / 1000)).$(printf '%02d' $((mw % 1000 / 10)))"

            gpu_w=""
            if command -v nvidia-smi >/dev/null 2>&1; then
              gpu_w=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits 2>/dev/null | head -1 || true)
            fi

            echo "$(date -u +%FT%TZ),''${cpu_w},''${gpu_w}" >> "$OUT"
          done
        ''}/bin/power-logging";
        StateDirectory = "power-logging";
        Restart = "on-failure";
        RestartSec = "30s";
        NoNewPrivileges = true;
      };
    };

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "power-cost" ''
        set -eu

        LOG="''${STATE_DIRECTORY:-/var/lib/power-logging}/power.csv"

        if [ "$#" -ne 1 ]; then
          echo "usage: power-cost <price-per-kWh>   e.g. power-cost 0.22" >&2
          exit 1
        fi

        case "$1" in
          ""|*[!.0-9]*)
            echo "power-cost: '$1' is not a valid price-per-kWh number" >&2
            exit 1
            ;;
        esac

        if [ ! -f "$LOG" ]; then
          echo "power-cost: no log at $LOG — is the power-logging service running?" >&2
          exit 1
        fi

        awk -F, -v rate="$1" '
          NR > 1 && $2 != "" {
            w += $2
            n++
            if ($3 != "") { gw += $3; gn++ }
          }
          END {
            if (n == 0) { print "power-cost: log has no samples yet" > "/dev/stderr"; exit 1 }
            cpu = w / n
            gpu = gn > 0 ? gw / gn : 0
            total = cpu + gpu
            kwh = total * 720 / 1000
            printf "avg power:   %.1f W (cpu %.1f W + gpu %.1f W)\n", total, cpu, gpu
            printf "kWh/month:   %.1f kWh\n", kwh
            printf "cost/month:  $%.2f (at $%s/kWh)\n", kwh * rate, rate
          }' "$LOG"
      '')
    ];
  };
}
