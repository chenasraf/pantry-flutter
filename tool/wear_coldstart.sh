#!/usr/bin/env bash
# Cold-start timing for a build already installed on a connected device.
#
# Reports three numbers per launch, which measure different things and diverge
# on a Flutter app:
#   TotalTime  — the system's own activity-launch timing, up to first frame
#   Displayed  — same moment, as the framework logs it
#   FullyDrawn — reportFullyDrawn(), which for Flutter is the first frame the
#                Dart UI actually rasterised. This is the one a user feels.
#
# Usage: tool/wear_coldstart.sh [-n runs] [-w warmups] [-l label] [-s serial]

set -euo pipefail

PACKAGE="dev.casraf.pantry"
ACTIVITY="dev.casraf.pantry.MainActivity"
RUNS=10
WARMUPS=2
LABEL=""
SERIAL=""

while getopts "n:w:l:s:p:a:h" opt; do
  case "$opt" in
    n) RUNS="$OPTARG" ;;
    w) WARMUPS="$OPTARG" ;;
    l) LABEL="$OPTARG" ;;
    s) SERIAL="$OPTARG" ;;
    p) PACKAGE="$OPTARG" ;;
    a) ACTIVITY="$OPTARG" ;;
    h) sed -n '2,12p' "$0"; exit 0 ;;
    *) exit 2 ;;
  esac
done

ADB=(adb)
[[ -n "$SERIAL" ]] && ADB=(adb -s "$SERIAL")

if ! "${ADB[@]}" shell pm path "$PACKAGE" >/dev/null 2>&1; then
  echo "not installed on the target: $PACKAGE" >&2
  exit 1
fi

device_model=$("${ADB[@]}" shell getprop ro.product.model | tr -d '\r')
device_sdk=$("${ADB[@]}" shell getprop ro.build.version.sdk | tr -d '\r')
echo "device:   $device_model (API $device_sdk)"
echo "package:  $PACKAGE"
[[ -n "$LABEL" ]] && echo "label:    $LABEL"
echo "runs:     $RUNS (after $WARMUPS discarded)"
echo

totals=()
displayed=()
fullydrawn=()

launch_once() {
  "${ADB[@]}" shell am force-stop "$PACKAGE" >/dev/null 2>&1
  # A launch straight after force-stop can still hit a warm page cache; the
  # pause lets the system settle so successive runs are comparable.
  sleep 2
  "${ADB[@]}" logcat -c >/dev/null 2>&1 || true

  local out
  out=$("${ADB[@]}" shell am start -W -n "$PACKAGE/$ACTIVITY" 2>&1 | tr -d '\r')
  local total
  total=$(printf '%s\n' "$out" | awk -F': ' '/^TotalTime/ {print $2}')

  # reportFullyDrawn arrives well after am start returns.
  sleep 4
  local log
  log=$("${ADB[@]}" logcat -d -s ActivityTaskManager:I 2>/dev/null | tr -d '\r' || true)

  local disp fully
  disp=$(printf '%s\n' "$log" | grep -F "Displayed $PACKAGE" | tail -1 |
    grep -oE '\+([0-9]+s)?[0-9]+ms' | tail -1 || true)
  fully=$(printf '%s\n' "$log" | grep -F "Fully drawn $PACKAGE" | tail -1 |
    grep -oE '\+([0-9]+s)?[0-9]+ms' | tail -1 || true)

  echo "$total|${disp:-}|${fully:-}"
}

# "+1s154ms" is not a number; normalise to milliseconds.
to_ms() {
  local v="${1#+}"
  [[ -z "$v" ]] && { echo ""; return; }
  local s=0 ms=0
  [[ "$v" =~ ([0-9]+)s ]] && s="${BASH_REMATCH[1]}"
  [[ "$v" =~ ([0-9]+)ms ]] && ms="${BASH_REMATCH[1]}"
  echo $((s * 1000 + ms))
}

stats() {
  local name="$1"; shift
  local -a v=("$@")
  [[ ${#v[@]} -eq 0 ]] && { printf '  %-11s no data\n' "$name"; return; }
  printf '%s\n' "${v[@]}" | sort -n | awk -v name="$name" '
    {a[NR]=$1; sum+=$1}
    END {
      med = (NR % 2) ? a[(NR+1)/2] : int((a[NR/2] + a[NR/2+1]) / 2)
      printf "  %-11s min %5d   median %5d   mean %6.1f   max %5d   n=%d\n",
        name, a[1], med, sum/NR, a[NR], NR
    }'
}

for ((i = 1; i <= WARMUPS + RUNS; i++)); do
  result=$(launch_once)
  IFS='|' read -r total disp fully <<<"$result"
  disp_ms=$(to_ms "$disp")
  fully_ms=$(to_ms "$fully")

  if ((i <= WARMUPS)); then
    printf '  warmup %d/%d  total=%-6s displayed=%-7s fullyDrawn=%s\n' \
      "$i" "$WARMUPS" "${total:-?}" "${disp_ms:-?}" "${fully_ms:-?}"
    continue
  fi

  printf '  run %2d/%d     total=%-6s displayed=%-7s fullyDrawn=%s\n' \
    "$((i - WARMUPS))" "$RUNS" "${total:-?}" "${disp_ms:-?}" "${fully_ms:-?}"

  [[ -n "$total" ]] && totals+=("$total")
  [[ -n "$disp_ms" ]] && displayed+=("$disp_ms")
  [[ -n "$fully_ms" ]] && fullydrawn+=("$fully_ms")
done

echo
echo "milliseconds${LABEL:+ — $LABEL}"
stats TotalTime "${totals[@]}"
stats Displayed "${displayed[@]}"
stats FullyDrawn "${fullydrawn[@]}"
