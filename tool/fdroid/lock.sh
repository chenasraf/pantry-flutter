#!/usr/bin/env bash
#
# Keep the pinned F-Droid lockfile (tool/fdroid/pubspec.lock) in step with the
# FLOSS pubspec. Applies the scanner swap — exactly what the release build's
# F-Droid job does first — then either:
#
#   check  resolve against the committed lock with `flutter pub get
#          --enforce-lockfile`, so a dependency added or bumped in pubspec.yaml
#          without regenerating the lock fails here instead of at release time
#   write  resolve fresh and capture the result as the new lock
#
# The working tree is restored byte-for-byte on exit (from a backup, not
# `git checkout`), so both modes are safe to run with uncommitted changes and as
# a pre-commit hook.
set -uo pipefail

mode="${1:-check}"
case "$mode" in
check | write) ;;
*)
  echo "usage: $(basename "$0") [check|write]" >&2
  exit 2
  ;;
esac

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

# The files tool/fdroid/apply.sh mutates in place.
files=(
  pubspec.yaml
  pubspec.lock
  lib/views/checklists/barcode_scanner/barcode_camera_scanner.dart
  packages/pantry_core/pubspec.yaml
  packages/pantry_core/lib/widgets/avif_image.dart
  android/app/build.gradle.kts
  android/app/src/main/kotlin/dev/casraf/pantry/DataLayerChannel.kt
)

backup="$(mktemp -d)"
restore() {
  for f in "${files[@]}"; do
    [ -f "$backup/$f" ] && cp "$backup/$f" "$f"
  done
  rm -rf "$backup"
  # Re-resolve the default (non-FLOSS) deps so the working tree's .dart_tool
  # isn't left pointing at the F-Droid variant. Skipped in CI (throwaway tree).
  if [ -z "${CI:-}" ]; then
    flutter pub get >/dev/null 2>&1 || true
  fi
}
trap restore EXIT

for f in "${files[@]}"; do
  mkdir -p "$backup/$(dirname "$f")"
  cp "$f" "$backup/$f"
done

if [ "$mode" = write ]; then
  echo "fdroid: resolving the FLOSS pubspec to refresh tool/fdroid/pubspec.lock…"
  if ! FDROID_REGEN_LOCK=1 tool/fdroid/apply.sh; then
    cat >&2 <<'EOF'

The FLOSS dependency set could not be resolved, so tool/fdroid/pubspec.lock is
unchanged and the release build's F-Droid job will fail.

Fix the conflict reported above in pubspec.yaml, then try again.
EOF
    exit 1
  fi

  if cmp -s pubspec.lock tool/fdroid/pubspec.lock; then
    echo "fdroid: lockfile already in sync."
  else
    cp pubspec.lock tool/fdroid/pubspec.lock
    echo "fdroid: updated tool/fdroid/pubspec.lock."
  fi
  exit 0
fi

echo "fdroid: verifying tool/fdroid/pubspec.lock satisfies the FLOSS pubspec…"
if tool/fdroid/apply.sh; then
  echo "fdroid: lockfile is in sync."
  exit 0
fi

cat >&2 <<'EOF'

tool/fdroid/pubspec.lock is out of sync with pubspec.yaml.

A dependency changed but the pinned F-Droid lockfile wasn't regenerated, so the
release build's F-Droid job (flutter pub get --enforce-lockfile) will fail.

Fix: run `make fdroid-lock`, then commit the updated tool/fdroid/pubspec.lock.
EOF
exit 1
