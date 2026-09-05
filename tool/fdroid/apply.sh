#!/usr/bin/env bash
#
# Swap the barcode scanner from Google ML Kit (mobile_scanner) to the FLOSS
# flutter_zxing, producing a fully-FLOSS build suitable for F-Droid.
#
# This MUTATES the working tree in place:
#   - pubspec.yaml:   mobile_scanner -> flutter_zxing
#   - the scanner:    lib/.../barcode_camera_scanner.dart <- fdroid/barcode_camera_scanner.dart
#   - the watch link: android/.../DataLayerChannel.kt <- fdroid/DataLayerChannel.kt
#   - build.gradle.kts: drop play-services-wearable and wear-remote-interactions
#
# Reverse it with `make fdroid-revert` (or `git checkout` of those paths). CI
# runs this in a throwaway checkout, so it never needs reverting there.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

impl="lib/views/checklists/barcode_scanner/barcode_camera_scanner.dart"
override="fdroid/barcode_camera_scanner.dart"
zxing_version="^2.3.0"

avif_impl="lib/widgets/avif_image.dart"
avif_override="fdroid/avif_image.dart"

link_impl="android/app/src/main/kotlin/dev/casraf/pantry/DataLayerChannel.kt"
link_override="fdroid/DataLayerChannel.kt"
gradle="android/app/build.gradle.kts"

for f in "$override" "$avif_override" "$link_override"; do
  if [ ! -f "$f" ]; then
    echo "fdroid: missing $f" >&2
    exit 1
  fi
done

if ! grep -q '^  mobile_scanner:' pubspec.yaml; then
  echo "fdroid: pubspec.yaml has no mobile_scanner dependency — already applied?" >&2
  exit 1
fi

# Dependency swap: drop the proprietary ML Kit scanner, add FLOSS zxing.
# -i.bak + rm keeps this portable across GNU (CI) and BSD/macOS sed.
sed -i.bak "s|^  mobile_scanner: .*\$|  flutter_zxing: ${zxing_version}|" pubspec.yaml
rm -f pubspec.yaml.bak

# Drop flutter_avif entirely: it ships prebuilt native blobs (libflutter_avif.so,
# wasm) with no buildable source, so F-Droid's scanner strips them and the
# rebuild can't match the reference APK. The FLOSS avif_image.dart below keeps
# the same API but decodes with Flutter's built-in codecs only.
sed -i.bak "/^  flutter_avif:/d" pubspec.yaml
rm -f pubspec.yaml.bak

# The Wear Data Layer is Google Play services, with no FLOSS equivalent to swap
# in, so watch pairing is the one feature the F-Droid build cannot carry. The
# stub keeps both channels registered and reports the link unavailable, which is
# what lets the pairing entry point hide itself rather than crash.
sed -i.bak '/play-services-wearable/d' "$gradle"
rm -f "$gradle.bak"

# wear-remote-interactions sits under F-Droid's com.google.android.gms signature
# block. It escapes the scanner today only because the scanner derives its
# dependency-line regexes from the flavors named in the recipe's `gradle:` field,
# which this recipe does not have — so `wearImplementation` is never one of the
# names it looks for. Nothing chose that; drop the line rather than depend on it.
# Free either way: it is a wear-only configuration and F-Droid builds --flavor
# phone, so it was never in the APK.
sed -i.bak '/wear-remote-interactions/d' "$gradle"
rm -f "$gradle.bak"

cp "$link_override" "$link_impl"

# Implementation swap: replace the ML Kit camera widget with the zxing one, and
# the AVIF-decoding image widgets with the native-codec-only versions.
cp "$override" "$impl"
cp "$avif_override" "$avif_impl"

# Reproducibility: pin the post-swap dependency set. The default pubspec.lock
# tracks mobile_scanner, so it can't lock this FLOSS variant; instead swap in the
# committed fdroid lock and resolve against it with --enforce-lockfile. Without
# this, `pub get` re-resolves flutter_zxing's subtree (camera_*, etc.) to
# whatever is latest at build time, so F-Droid's later rebuild can pick up
# different transitive versions than the published reference APK and fail the
# byte-for-byte reproducible check.
#
# FDROID_REGEN_LOCK=1 resolves fresh (unpinned) instead, so `make fdroid-lock`
# can capture an updated lock after dependencies change.
if [ "${FDROID_REGEN_LOCK:-}" = "1" ]; then
  flutter pub get
else
  cp tool/fdroid/pubspec.lock pubspec.lock
  flutter pub get --enforce-lockfile
fi

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
