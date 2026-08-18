#!/usr/bin/env bash
#
# Swap the barcode scanner from Google ML Kit (mobile_scanner) to the FLOSS
# flutter_zxing, producing a fully-FLOSS build suitable for F-Droid.
#
# This MUTATES the working tree in place:
#   - pubspec.yaml:   mobile_scanner -> flutter_zxing
#   - the scanner:    lib/.../barcode_camera_scanner.dart <- fdroid/barcode_camera_scanner.dart
#
# Reverse it with `make fdroid-revert` (or `git checkout` of those paths). CI
# runs this in a throwaway checkout, so it never needs reverting there.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

impl="lib/views/checklists/barcode_scanner/barcode_camera_scanner.dart"
override="fdroid/barcode_camera_scanner.dart"
zxing_version="^2.3.0"

if [ ! -f "$override" ]; then
  echo "fdroid: missing $override" >&2
  exit 1
fi

if ! grep -q '^  mobile_scanner:' pubspec.yaml; then
  echo "fdroid: pubspec.yaml has no mobile_scanner dependency — already applied?" >&2
  exit 1
fi

# Dependency swap: drop the proprietary ML Kit scanner, add FLOSS zxing.
# -i.bak + rm keeps this portable across GNU (CI) and BSD/macOS sed.
sed -i.bak "s|^  mobile_scanner: .*\$|  flutter_zxing: ${zxing_version}|" pubspec.yaml
rm -f pubspec.yaml.bak

# Implementation swap: replace the ML Kit camera widget with the zxing one.
cp "$override" "$impl"

flutter pub get

# Native-library reproducibility for F-Droid.
#
# Every Android .so the linker emits carries a .note.gnu.build-id derived from
# the pre-strip binary, so host-specific paths in its debug info make the id
# differ between build machines. F-Droid compares the published APK against its
# own rebuild byte-for-byte, and a mismatched build-id fails that check (#131).
# Drop the note by injecting --build-id=none into every bundled native lib's
# link flags. `flutter pub get` above populated $PUB_CACHE, so the package
# sources are present to patch. Kept here (not only in CI) so the F-Droid
# recipe, which runs this script, gets reproducible libs too.
pub_cache="${PUB_CACHE:-$HOME/.pub-cache}"
for cml in \
  "$pub_cache"/hosted/pub.dev/jni-*/src/CMakeLists.txt \
  "$pub_cache"/hosted/pub.dev/flutter_zxing-*/src/CMakeLists.txt; do
  [ -e "$cml" ] || continue
  grep -q -- '--build-id=none' "$cml" && continue
  sed -i.bak -e 's/-Wl,/-Wl,--build-id=none,/' "$cml"
  rm -f "$cml.bak"
  echo "fdroid: stripped native build-id in $cml"
done

echo "fdroid: applied flutter_zxing scanner variant (pubspec + $impl)."
