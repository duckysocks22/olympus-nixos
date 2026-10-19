STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/olympus-vm"
SSH_KEY="${OLYMPUS_VM_SSH_KEY:-$HOME/.ssh/id_ed25519}"
DEFAULT_HOSTS="athena-nixos circe-nixos dionysus-nixos ariadne-nixos"
HOSTS="${OLYMPUS_VM_HOSTS:-$DEFAULT_HOSTS}"
read -r -a HOST_ARRAY <<< "$HOSTS"
PORT_START=2222
PORT_END=2231
VNC_START=10
VNC_END=19
BOOT_TIMEOUT="${OLYMPUS_VM_BOOT_TIMEOUT:-180}"

SELF="$0"
if [[ "$SELF" != /* ]]; then
  SELF="$(command -v -- "$SELF" || printf '%s' "$0")"
fi
SELF="$(readlink -f -- "$SELF" 2>/dev/null || printf '%s' "$SELF")"

die() {
  printf 'vm-test: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: vm-test <command> [args]

Commands:
  hosts                          List hosts with a VM variant
  start <host> [options]         Build and boot a headless VM
    --display auto|vnc|egl|none|gtk
                                 Display backend (default: auto = software VNC;
                                 egl adds GL but cannot be screendumped)
    --port <port>                Forwarded SSH port (default: first free)
    --owner-pid <pid>            Stop the VM when this process exits (used by pi)
  switch <host>                  Apply the current flake config into the running VM
  stop <host>                    Stop the VM and discard its overlay
  status [host]                  Show running VMs
  ssh <host> [command...]        Run a command as root (interactive without one)
  logs <host> [-f] [lines]       Show the guest serial console log
  screenshot <host> [file] [--guest]
                                 Capture via QEMU (default) or from inside the
                                 niri session (works with --display egl)
  vnc <host>                     Print the VNC endpoint for viewing the desktop

Environment:
  OLYMPUS_REPO             Flake checkout (default: git root, else ~/olympus-nixos)
  OLYMPUS_VM_SSH_KEY       SSH private key (default: ~/.ssh/id_ed25519)
  OLYMPUS_VM_HOSTS         Space-separated host list override
  OLYMPUS_VM_BOOT_TIMEOUT  Seconds to wait for SSH (default: 180)
EOF
}

host_known() {
  local candidate="$1" h
  for h in "${HOST_ARRAY[@]}"; do
    if [[ "$h" == "$candidate" ]]; then
      return 0
    fi
  done
  return 1
}

require_host() {
  [[ -n "${1:-}" ]] || die "missing host argument"
  host_known "$1" || die "unknown host '$1' (known: $HOSTS)"
}

host_dir() {
  printf '%s/%s\n' "$STATE_ROOT" "$1"
}

read_pid() {
  cat "$(host_dir "$1")/pid" 2>/dev/null || true
}

is_running() {
  local pid
  pid="$(read_pid "$1")"
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

repo_root() {
  local repo="${OLYMPUS_REPO:-}"
  if [[ -z "$repo" ]]; then
    repo="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || true)"
  fi
  if [[ -z "$repo" || ! -f "$repo/flake.nix" ]]; then
    repo="$HOME/olympus-nixos"
  fi
  [[ -f "$repo/flake.nix" ]] || die "cannot locate olympus-nixos flake (set OLYMPUS_REPO)"
  printf '%s\n' "$repo"
}

pick_port() {
  local p
  for ((p = PORT_START; p <= PORT_END; p++)); do
    if [[ -z "$(ss -H -ltn "sport = :$p")" ]]; then
      printf '%s\n' "$p"
      return 0
    fi
  done
  die "no free forwarded port in ${PORT_START}-${PORT_END}"
}

pick_vnc_display() {
  local d port
  for ((d = VNC_START; d <= VNC_END; d++)); do
    port=$((5900 + d))
    if [[ -z "$(ss -H -ltn "sport = :$port")" ]]; then
      printf '%s\n' "$d"
      return 0
    fi
  done
  die "no free VNC display in ${VNC_START}-${VNC_END}"
}

ssh_nix_opts() {
  printf '%s\n' "-p $1 -i $SSH_KEY -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -o LogLevel=ERROR"
}

guest_ssh() {
  local host="$1"
  shift
  local port
  port="$(cat "$(host_dir "$host")/port" 2>/dev/null || true)"
  [[ -n "$port" ]] || die "$host is not running"
  ssh -p "$port" \
    -i "$SSH_KEY" \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=5 \
    -o ServerAliveInterval=15 \
    -o LogLevel=ERROR \
    root@127.0.0.1 "$@"
}

wait_for_ssh() {
  local host="$1"
  local deadline=$((SECONDS + BOOT_TIMEOUT))
  while ((SECONDS < deadline)); do
    if ! is_running "$host"; then
      return 1
    fi
    if guest_ssh "$host" true >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  return 1
}

launch_vm() {
  local drv="$1"
  local dir="$2"
  local display="$3"
  local vnc_display="${4:-}"
  local pid
  local -a display_args
  case "$display" in
    vnc)
      display_args=(-display "vnc=127.0.0.1:$vnc_display" -vga none -device virtio-gpu-pci)
      ;;
    egl)
      if [[ -n "$vnc_display" ]]; then
        display_args=(-display egl-headless -vnc "127.0.0.1:$vnc_display" -vga none -device virtio-gpu-gl-pci)
      else
        display_args=(-display egl-headless -vga none -device virtio-gpu-gl-pci)
      fi
      ;;
    none)
      display_args=(-display none -vga none -device virtio-gpu-pci)
      ;;
    gtk)
      display_args=(-display "gtk,gl=on" -vga none -device virtio-gpu-gl-pci)
      ;;
    *)
      die "unknown display '$display'"
      ;;
  esac
  "$drv/bin/disko-vm" "${display_args[@]}" \
    -serial "file:$dir/serial.log" \
    -monitor "unix:$dir/qmp.sock,server=on,wait=off" \
    >>"$dir/qemu.log" 2>&1 </dev/null &
  pid=$!
  printf '%s\n' "$pid" > "$dir/pid"

  local qemu=""
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    qemu="$(find_qemu "$dir" "$pid")"
    if [[ -n "$qemu" ]]; then
      break
    fi
    sleep 0.2
  done
  if [[ -n "$qemu" ]]; then
    printf '%s\n' "$qemu" > "$dir/qemu.pid"
  fi
}

start_vm() {
  local host="$1"
  local display="$2"
  local port="$3"
  local owner_pid="${4:-}"
  local dir repo drv pid vnc_display=""
  dir="$(host_dir "$host")"
  mkdir -p "$dir"

  printf '%s\n' "$$" > "$dir/runner.pid"
  if [[ -n "$owner_pid" ]]; then
    printf '%s\n' "$owner_pid" > "$dir/owner.pid"
    ps -o lstart= -p "$owner_pid" 2>/dev/null | sed 's/^ *//' > "$dir/owner.start" || true
    setsid "$SELF" watch "$host" >>"$dir/watchdog.log" 2>&1 &
    sleep 0.2
  fi

  repo="$(repo_root)"

  printf 'Building %s VM...\n' "$host" >&2
  drv="$(nix build --no-link --print-out-paths \
    "$repo#nixosConfigurations.$host.config.system.build.vmWithDisko")"
  [[ -x "$drv/bin/disko-vm" ]] || die "unexpected VM derivation: $drv"

  case "$display" in
    auto | vnc)
      vnc_display="$(pick_vnc_display)"
      printf '%s\n' "$vnc_display" > "$dir/vnc"
      launch_vm "$drv" "$dir" "vnc" "$vnc_display"
      sleep 3
      ;;
    egl)
      vnc_display="$(pick_vnc_display)"
      printf '%s\n' "$vnc_display" > "$dir/vnc"
      launch_vm "$drv" "$dir" "$display" "$vnc_display"
      sleep 3
      ;;
    none) launch_vm "$drv" "$dir" "none"; sleep 3 ;;
    gtk) launch_vm "$drv" "$dir" "gtk"; sleep 3 ;;
    *) die "unknown display '$display' (auto, vnc, egl, none, gtk)" ;;
  esac

  if ! is_running "$host"; then
    tail -n 40 "$dir/qemu.log" >&2 || true
    die "$host failed to start"
  fi

  printf '%s\n' "$port" > "$dir/port"
  printf 'Waiting for SSH on 127.0.0.1:%s...\n' "$port" >&2
  if ! wait_for_ssh "$host"; then
    tail -n 60 "$dir/serial.log" >&2 || true
    tail -n 20 "$dir/qemu.log" >&2 || true
    printf 'VM %s is still running (pid %s). Inspect with: vm-test logs %s\n' \
      "$host" "$(read_pid "$host")" "$host" >&2
    return 1
  fi

  pid="$(read_pid "$host")"
  printf '%s running (pid %s, port %s)\n' "$host" "$pid" "$port"
  printf '  ssh:    vm-test ssh %s -- <command>\n' "$host"
  printf '  screen: vm-test screenshot %s\n' "$host"
  if [[ -n "$vnc_display" ]]; then
    printf '  vnc:    vncviewer 127.0.0.1:%s (port %s)\n' "$vnc_display" "$((5900 + vnc_display))"
  fi
  printf '  serial: %s\n' "$dir/serial.log"
}

cmd_hosts() {
  local h
  for h in "${HOST_ARRAY[@]}"; do
    printf '%s\n' "$h"
  done
}

cmd_start() {
  local host="" display="auto" port_override="" owner_pid=""
  while (($#)); do
    case "$1" in
      --display)
        display="${2:-}"
        shift 2
        ;;
      --display=*)
        display="${1#*=}"
        shift
        ;;
      --port)
        port_override="${2:-}"
        shift 2
        ;;
      --port=*)
        port_override="${1#*=}"
        shift
        ;;
      --owner-pid)
        owner_pid="${2:-}"
        shift 2
        ;;
      --owner-pid=*)
        owner_pid="${1#*=}"
        shift
        ;;
      -h | --help)
        usage
        return 0
        ;;
      -*)
        die "unknown option '$1'"
        ;;
      *)
        [[ -z "$host" ]] || die "start takes exactly one host"
        host="$1"
        shift
        ;;
    esac
  done

  require_host "$host"
  [[ -f "$SSH_KEY" ]] || die "ssh key not found: $SSH_KEY (set OLYMPUS_VM_SSH_KEY)"
  if is_running "$host"; then
    die "$host already running (pid $(read_pid "$host"), port $(cat "$(host_dir "$host")/port"))"
  fi
  rm -rf "$(host_dir "$host")"

  local port
  if [[ -n "$port_override" ]]; then
    port="$port_override"
    [[ "$port" =~ ^[0-9]+$ ]] || die "invalid port '$port'"
    ((port >= PORT_START && port <= PORT_END)) \
      || die "port must be in ${PORT_START}-${PORT_END}"
  else
    port="$(pick_port)"
  fi

  if [[ -n "$owner_pid" ]]; then
    [[ "$owner_pid" =~ ^[0-9]+$ ]] || die "invalid owner pid '$owner_pid'"
    kill -0 "$owner_pid" 2>/dev/null || die "owner process $owner_pid is not running"
  fi

  start_vm "$host" "$display" "$port" "$owner_pid"
}

find_qemu() {
  local dir="$1" wrapper="${2:-}" qemu=""
  qemu="$(pgrep -f -- "-serial file:$dir/serial.log" | head -n 1 || true)"
  if [[ -z "$qemu" && -n "$wrapper" ]]; then
    qemu="$(pgrep -P "$wrapper" | head -n 1 || true)"
  fi
  printf '%s\n' "$qemu"
}

qemu_overlay_dir() {
  [[ -r "/proc/$1/cmdline" ]] || return 0
  tr '\0' '\n' < "/proc/$1/cmdline" 2>/dev/null \
    | sed -n 's#.*file=\(/tmp/[^,]*\)/main\.qcow2.*#\1#p' \
    | head -n 1 || true
}

qemu_xchg_dir() {
  [[ -r "/proc/$1/cmdline" ]] || return 0
  tr '\0' '\n' < "/proc/$1/cmdline" 2>/dev/null \
    | sed -n 's#.*path=\(/tmp/nix-vm\.[^,]*\)/xchg.*#\1#p' \
    | head -n 1 || true
}

kill_vm_cmdline() {
  local dir="$1" pattern pid overlay xchg found
  pattern="-serial file:$dir/serial.log"
  for _ in 1 2 3; do
    found=0
    while IFS= read -r pid; do
      [[ -n "$pid" ]] || continue
      found=1
      overlay="$(qemu_overlay_dir "$pid")"
      xchg="$(qemu_xchg_dir "$pid")"
      kill -TERM "$pid" 2>/dev/null || true
      sleep 0.2
      kill -KILL "$pid" 2>/dev/null || true
      if [[ -n "$overlay" && -d "$overlay" ]]; then
        rm -rf "$overlay"
      fi
      if [[ -n "$xchg" && -d "$xchg" ]]; then
        rm -rf "$xchg"
      fi
    done < <(pgrep -f -- "$pattern" || true)
    if ((found == 0)); then
      return 0
    fi
    sleep 0.5
  done
}

cmd_watch() {
  local host="$1"
  local dir owner owner_start
  dir="$(host_dir "$host")"
  [[ -d "$dir" ]] || return 0
  printf '%s\n' "$$" > "$dir/watchdog.pid"

  owner="$(cat "$dir/owner.pid" 2>/dev/null || true)"
  [[ -n "$owner" ]] || return 0
  owner_start="$(cat "$dir/owner.start" 2>/dev/null || true)"

  local state current
  while true; do
    state="$(ps -o stat= -p "$owner" 2>/dev/null | tr -d ' ' || true)"
    current="$(ps -o lstart= -p "$owner" 2>/dev/null | sed 's/^ *//' || true)"
    if [[ -z "$current" || "$state" == Z* ]]; then
      break
    fi
    if [[ -n "$owner_start" && "$current" != "$owner_start" ]]; then
      break
    fi
    sleep 3
  done

  local wrapper qemu runner waited
  wrapper="$(read_pid "$host")"
  qemu="$(cat "$dir/qemu.pid" 2>/dev/null || true)"
  runner="$(cat "$dir/runner.pid" 2>/dev/null || true)"

  if [[ -z "$qemu" ]] || ! kill -0 "$qemu" 2>/dev/null; then
    qemu="$(find_qemu "$dir" "$wrapper")"
  fi

  if [[ -n "$qemu" ]] && kill -0 "$qemu" 2>/dev/null; then
    kill -TERM "$qemu" 2>/dev/null || true
    waited=0
    while kill -0 "$qemu" 2>/dev/null && ((waited < 20)); do
      sleep 0.5
      waited=$((waited + 1))
    done
    kill -KILL "$qemu" 2>/dev/null || true
  fi

  if [[ -n "$wrapper" ]] && kill -0 "$wrapper" 2>/dev/null; then
    kill -TERM "$wrapper" 2>/dev/null || true
    sleep 0.5
    kill -KILL "$wrapper" 2>/dev/null || true
  fi

  if [[ -n "$runner" ]] && kill -0 "$runner" 2>/dev/null; then
    kill -TERM "$runner" 2>/dev/null || true
  fi

  kill_vm_cmdline "$dir"
  rm -rf "$dir"
}

cmd_stop() {
  local host="$1"
  require_host "$host"
  local dir pid qemu target waited overlay="" xchg=""
  dir="$(host_dir "$host")"

  if ! is_running "$host"; then
    rm -rf "$dir"
    printf '%s is not running\n' "$host"
    return 0
  fi

  local watchdog
  watchdog="$(cat "$dir/watchdog.pid" 2>/dev/null || true)"
  if [[ -n "$watchdog" ]]; then
    kill -TERM "$watchdog" 2>/dev/null || true
  fi

  pid="$(read_pid "$host")"
  qemu="$(find_qemu "$dir" "$pid")"
  target="${qemu:-$pid}"

  if [[ -n "$qemu" ]]; then
    overlay="$(qemu_overlay_dir "$qemu")"
    xchg="$(qemu_xchg_dir "$qemu")"
  fi

  kill -TERM "$target" 2>/dev/null || true
  waited=0
  while is_running "$host" && ((waited < 40)); do
    sleep 0.5
    waited=$((waited + 1))
  done
  if is_running "$host"; then
    kill -KILL "$target" 2>/dev/null || true
    kill -KILL "$pid" 2>/dev/null || true
  fi

  kill_vm_cmdline "$dir"
  if [[ -n "$overlay" && -d "$overlay" ]]; then
    rm -rf "$overlay"
  fi
  if [[ -n "$xchg" && -d "$xchg" ]]; then
    rm -rf "$xchg"
  fi
  rm -rf "$dir"
  printf '%s stopped\n' "$host"
}

cmd_status() {
  local hosts=("${HOST_ARRAY[@]}")
  if (($#)); then
    require_host "$1"
    hosts=("$1")
  fi
  local h dir pid port vnc
  for h in "${hosts[@]}"; do
    dir="$(host_dir "$h")"
    if is_running "$h"; then
      pid="$(read_pid "$h")"
      port="$(cat "$dir/port" 2>/dev/null || true)"
      vnc="$(cat "$dir/vnc" 2>/dev/null || true)"
      printf '%-16s running  pid=%-8s ssh=%-5s vnc=%-16s serial=%s\n' \
        "$h" "$pid" "$port" "${vnc:+127.0.0.1:$vnc}" "$dir/serial.log"
    else
      if [[ -d "$dir" ]]; then
        rm -rf "$dir"
      fi
      printf '%-16s stopped\n' "$h"
    fi
  done
}

cmd_ssh() {
  local host="$1"
  shift
  require_host "$host"
  if [[ "${1:-}" == "--" ]]; then
    shift
  fi
  guest_ssh "$host" "$@"
}

cmd_logs() {
  local host="$1"
  shift
  require_host "$host"
  local follow=0 lines=80 dir
  while (($#)); do
    case "$1" in
      -f | --follow)
        follow=1
        shift
        ;;
      *)
        lines="$1"
        shift
        ;;
    esac
  done
  dir="$(host_dir "$host")"
  [[ -f "$dir/serial.log" ]] || die "no serial log for $host"
  if ((follow)); then
    tail -n "$lines" -F "$dir/serial.log"
  else
    tail -n "$lines" "$dir/serial.log"
  fi
}

cmd_vnc() {
  local host="$1"
  require_host "$host"
  is_running "$host" || die "$host is not running"
  local display
  display="$(cat "$(host_dir "$host")/vnc" 2>/dev/null || true)"
  [[ -n "$display" ]] || die "$host has no VNC display; restart with --display vnc"
  printf '127.0.0.1:%s\n' "$display"
}

cmd_switch() {
  local host="$1"
  require_host "$host"
  is_running "$host" || die "$host is not running"

  local repo port out current deadline
  repo="$(repo_root)"
  port="$(cat "$(host_dir "$host")/port")"

  printf 'Building %s VM system...\n' "$host" >&2
  out="$(nix build --no-link --print-out-paths \
    "$repo#nixosConfigurations.$host.config.virtualisation.vmVariantWithDisko.system.build.toplevel")"

  printf 'Copying closure to %s...\n' "$host" >&2
  NIX_SSHOPTS="$(ssh_nix_opts "$port")" nix copy --to "ssh-ng://root@127.0.0.1" "$out"

  printf 'Activating...\n' >&2
  guest_ssh "$host" "nix-env --profile /nix/var/nix/profiles/system --set '$out'"
  guest_ssh "$host" "systemd-run --collect --unit=vm-test-switch --property=Type=oneshot --wait --pipe '$out/bin/switch-to-configuration' switch" || true

  deadline=$((SECONDS + BOOT_TIMEOUT))
  while ((SECONDS < deadline)); do
    if guest_ssh "$host" true >/dev/null 2>&1; then
      current="$(guest_ssh "$host" readlink -f /run/current-system 2>/dev/null || true)"
      if [[ "$current" == "$out" ]]; then
        printf '%s switched to %s\n' "$host" "$out"
        return 0
      fi
    fi
    sleep 2
  done
  die "$host switch did not activate (running ${current:-unknown})"
}

cmd_screenshot() {
  local host="" out="" guest=0
  while (($#)); do
    case "$1" in
      --guest)
        guest=1
        shift
        ;;
      -h | --help)
        usage
        return 0
        ;;
      -*)
        die "unknown option '$1'"
        ;;
      *)
        if [[ -z "$host" ]]; then
          host="$1"
        elif [[ -z "$out" ]]; then
          out="$1"
        else
          die "too many arguments"
        fi
        shift
        ;;
    esac
  done

  require_host "$host"
  is_running "$host" || die "$host is not running"

  local dir
  dir="$(host_dir "$host")"
  [[ -n "$out" ]] || out="$dir/$host.png"

  if ((guest)); then
    local remote="/tmp/vm-test-shot-$$.png"
    if ! guest_ssh "$host" bash -s -- "$remote" <<'REMOTE' | base64 -d > "$out"
set -eu
pid=$(pgrep -x niri | head -n1)
[ -n "$pid" ] || { echo 'no niri session found' >&2; exit 1; }
uid=$(stat -c %u "/proc/$pid")
user=$(getent passwd "$uid" | cut -d: -f1)
runtime=$(tr '\0' '\n' < "/proc/$pid/environ" | sed -n 's/^XDG_RUNTIME_DIR=//p')
display=$(tr '\0' '\n' < "/proc/$pid/environ" | sed -n 's/^WAYLAND_DISPLAY=//p')
[ -n "$runtime" ] || runtime="/run/user/$uid"
if [ -z "$display" ]; then
  socket=$(ls "$runtime"/wayland-* 2>/dev/null | head -n1 || true)
  [ -n "$socket" ] && display=$(basename "$socket")
fi
[ -n "${display:-}" ] || { echo 'no wayland socket found' >&2; exit 1; }
runuser -u "$user" -- env XDG_RUNTIME_DIR="$runtime" WAYLAND_DISPLAY="$display" grim "$1"
base64 -w0 "$1"
rm -f "$1"
REMOTE
    then
      rm -f "$out"
      die "guest screenshot failed"
    fi
  else
    local ppm
    ppm="$dir/screen.ppm"
    rm -f "$ppm"

    printf 'screendump %s\n' "$ppm" \
      | socat - "UNIX-CONNECT:$dir/qmp.sock" >/dev/null 2>&1 || true

    local waited=0
    while [[ ! -s "$ppm" ]] && ((waited < 50)); do
      sleep 0.1
      waited=$((waited + 1))
    done
    [[ -s "$ppm" ]] || die "screendump failed; use --guest (or restart with --display vnc)"

    pnmtopng "$ppm" > "$out"
  fi

  printf '%s\n' "$out"
}

command="${1:-}"
shift || true

case "$command" in
  hosts) cmd_hosts ;;
  start) cmd_start "$@" ;;
  stop) cmd_stop "$@" ;;
  status) cmd_status "$@" ;;
  ssh) cmd_ssh "$@" ;;
  logs) cmd_logs "$@" ;;
  switch) cmd_switch "$@" ;;
  screenshot) cmd_screenshot "$@" ;;
  vnc) cmd_vnc "$@" ;;
  watch) cmd_watch "$@" ;;
  -h | --help | help | "") usage ;;
  *) die "unknown command '$command' (try --help)" ;;
esac
