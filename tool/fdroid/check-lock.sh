#!/usr/bin/env bash
#
# Verify the pinned F-Droid lockfile (tool/fdroid/pubspec.lock) still satisfies
# the FLOSS pubspec. Applies the scanner swap against the committed lock with
# `flutter pub get --enforce-lockfile` — exactly what the release build's
# F-Droid job does first — so a dependency added or bumped in pubspec.yaml
# without regenerating the lock is caught here instead of failing the release.
#
# The working tree is restored byte-for-byte on exit (from a backup, not
# `git checkout`), so this is safe to run with uncommitted changes and as a
# pre-commit hook. Fix a failure with `make fdroid-lock`.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

# The files tool/fdroid/apply.sh mutates in place.
files=(
  pubspec.yaml
  pubspec.lock
  lib/views/checklists/barcode_scanner/barcode_camera_scanner.dart
  lib/widgets/avif_image.dart
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
