# F-Droid build variant

F-Droid only accepts fully-FLOSS builds. The default app uses Google ML Kit
(`mobile_scanner`) for barcode scanning, which pulls in a proprietary Google
binary and disqualifies the build. This directory holds the pieces that swap
that scanner for the FLOSS [`flutter_zxing`](https://pub.dev/packages/flutter_zxing)
so an F-Droid-eligible APK can be produced from the same source tree.

The zxing scanner is only used on this Android/F-Droid variant. iOS and the
store builds keep ML Kit, so the historical iOS-specific `flutter_zxing` fork is
no longer needed — this variant uses the published package.

## How the swap works

Flutter has no per-flavor package dependencies: any package listed in
`pubspec.yaml` is compiled and registered into **every** build. So a runtime
flavor flag can't keep a non-FLOSS package out of the F-Droid APK — the
dependency itself has to differ. The swap is therefore done at build time by
[`tool/fdroid/apply.sh`](../tool/fdroid/apply.sh), which:

1. rewrites `pubspec.yaml`: `mobile_scanner` → `flutter_zxing`, and removes
   `flutter_avif`;
2. overwrites `lib/views/checklists/barcode_scanner/barcode_camera_scanner.dart`
   with `fdroid/barcode_camera_scanner.dart` (this directory's zxing scanner);
3. overwrites `lib/widgets/avif_image.dart` with `fdroid/avif_image.dart` (the
   AVIF-free image widgets).

Everything else — the `BarcodeScanView.scan()` entry point, the manual-entry
dialog, the Open Food Facts attribution, every `AvifNetworkImage` call site — is
shared and untouched. Each override file exposes the same public API as the file
it replaces (`BarcodeCameraScanner`; `AvifNetworkImage`/`AvifMemoryImage`/
`AvifAware*Image`), so the shared code compiles against either.

### Why `flutter_avif` is removed, not swapped

`flutter_avif` decodes AVIF images, but it ships **prebuilt native blobs**
(`libflutter_avif.so`, web `.wasm`, etc.) with no buildable source. F-Droid's
scanner deletes such blobs at build time, so its rebuild lacks them while the
reference APK still carries them — the reproducible check can never match. There
is no FLOSS drop-in, so the F-Droid variant drops AVIF support entirely:
`fdroid/avif_image.dart` keeps the same widgets but decodes with Flutter's
built-in codecs (JPEG/PNG/WebP/GIF) only. Raw AVIF originals won't render on the
F-Droid build; Nextcloud's preview endpoint transcodes to JPEG, so the common
case is unaffected.

`fdroid/**` is excluded from `flutter analyze` (see `analysis_options.yaml`)
because its zxing import isn't a dependency of the default build. Once
`apply.sh` copies the files into `lib/`, they are analyzed and built normally.

## Building locally

```sh
make android-build-apk-fdroid    # apply swap + build split-per-ABI APKs
make android-release-apk-fdroid  # + copy to build/release/ as pantry-<ver>-fdroid-<abi>.apk
make fdroid-revert               # restore pubspec + swapped files to the default build
```

`apply.sh` leaves the working tree modified. Run `make fdroid-revert` when done
(CI builds in a fresh checkout, so it doesn't need to).

A swapped tree builds the `phone` flavor only. `apply.sh` drops
`androidx.wear:wear-remote-interactions`, which the wear `MainActivity` imports,
so `make wear-build-apk` fails to compile until `make fdroid-revert` runs. That
is deliberate: watch pairing is the one feature a FLOSS build cannot carry, so a
wear APK built from a swapped tree would be wrong rather than merely limited.

## CI

The `build-android-fdroid` job in `.github/workflows/release.yml` runs on every
release: it applies the swap and uploads `pantry-<version>-fdroid-<abi>.apk`
alongside the normal APKs. Point the F-Droid repository at those `-fdroid`
artifacts, not the default ones. The job builds **one ABI at a time** with
`--target-platform`, the same way the `fdroiddata` recipe builds each
versionCode — see below.

## Reproducible builds

F-Droid verifies our published APK by rebuilding it from source and comparing
byte-for-byte. Four things have to match between the host that publishes the
reference APK (our CI) and the host that rebuilds it (F-Droid):

### 1. No unverifiable prebuilt blobs

F-Droid's scanner strips any bundled binary it can't build from source. The
`mobile_scanner` swap and the `flutter_avif` removal above exist for this reason:
whatever the scanner deletes on F-Droid's side must be absent from our reference
APK too, or the two diverge. This is what made the check fail on 0.27.1/0.27.2 —
`flutter_avif`'s prebuilt `.so`/`.wasm` were in the reference APK but scrubbed
from F-Droid's rebuild.

### 2. Pinned dependencies

`apply.sh` rewrites `pubspec.yaml`, so the default `pubspec.lock` (which tracks
`mobile_scanner`) no longer applies. A plain `flutter pub get` would then
re-resolve `flutter_zxing`'s subtree — `camera_*` and other transitives — to
whatever is newest at build time, so a rebuild weeks later can pick up different
versions than the reference APK and diverge. To pin it, `tool/fdroid/pubspec.lock`
holds the resolved post-swap lock; `apply.sh` copies it into place and runs
`flutter pub get --enforce-lockfile`.

Regenerate it whenever dependencies change:

```sh
make fdroid-lock   # re-resolves the swapped tree, rewrites tool/fdroid/pubspec.lock
```

Commit the result. `--enforce-lockfile` fails the build loudly if the committed
lock ever drifts from `pubspec.yaml`.

### 3. Identical build command (per-ABI, and flavored)

The `fdroiddata` recipe builds each ABI as its own versionCode with
`flutter build apk --release --flavor phone --split-per-abi --target-platform=<plat>`,
collecting `build/app/outputs/flutter-apk/app-<abi>-phone-release.apk`. A plain
multi-ABI `--split-per-abi` produces per-APK output that differs from the
isolated per-ABI build, so our CI and `make android-build-apk-fdroid` build the
three ABIs one at a time with the matching `--target-platform`
(`android-arm`, `android-arm64`, `android-x64`), running `flutter clean` between
them to keep each build isolated as F-Droid does.

**`--flavor phone` is not optional, and omitting it does not fail.** Gradle's
`assembleRelease` is the aggregate task over every flavor of the release build
type, so a flavorless invocation assembles *both* flavors and writes
`app-<abi>-phone-release.apk` and `app-<abi>-wear-release.apk`. It then exits 0
announcing `✓ Built …/app-<abi>-release.apk` — a path it did not write — and
rewrites that path's `.sha1` sidecar, so any stale APK left there from before the
flavor split is freshly and correctly checksummed. On a swapped tree it does not
get that far: `apply.sh` strips `wear-remote-interactions`, so assembling the
wear flavor fails to compile. The hazard is a warm tree with no swap applied,
which is why `android-build-apk-fdroid` runs `flutter clean` before each ABI.

### 4. Stable native build-ids

The linker stamps each compiled `.so` with a `.note.gnu.build-id` derived from
the pre-strip binary, so host-specific paths in the debug info give the same
code a different build-id on a different machine (#131). `apply.sh` neutralises
this by injecting `--build-id=none` into the link flags of every **source-built**
native lib's CMakeLists — currently `jni` and `flutter_zxing` (the zxing
scanner's `libflutter_zxing.so`).

**Because all four live in `apply.sh` (plus the committed lock and the CI/Make
build commands), the `fdroiddata` recipe stays reproducible only if it runs
`tool/fdroid/apply.sh`** in its `prebuild` (it must run it anyway for the scanner
swap) and builds per-ABI with `--target-platform`. Since these fixes changed
source, F-Droid picks them up only from a **release tag that contains them** —
an older tag rebuilds with its own (unpinned) `apply.sh`.
