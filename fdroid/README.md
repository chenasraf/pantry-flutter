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
flavor flag can't keep ML Kit out of the F-Droid APK — the dependency itself has
to differ. The swap is therefore done at build time by
[`tool/fdroid/apply.sh`](../tool/fdroid/apply.sh), which:

1. rewrites `pubspec.yaml`: `mobile_scanner` → `flutter_zxing`, and
2. overwrites `lib/views/checklists/barcode_scanner/barcode_camera_scanner.dart`
   with `fdroid/barcode_camera_scanner.dart` (this directory's zxing scanner).

Everything else — the `BarcodeScanView.scan()` entry point, the manual-entry
dialog, the Open Food Facts attribution — is shared and untouched. Both scanner
files expose the same `BarcodeCameraScanner` widget, so the shared code compiles
against either.

`fdroid/**` is excluded from `flutter analyze` (see `analysis_options.yaml`)
because its zxing import isn't a dependency of the default build. Once
`apply.sh` copies the file into `lib/`, it is analyzed and built normally.

## Building locally

```sh
make android-build-apk-fdroid    # apply swap + build split-per-ABI APKs
make android-release-apk-fdroid  # + copy to build/release/ as pantry-<ver>-fdroid-<abi>.apk
make fdroid-revert               # restore pubspec + scanner to the ML Kit default
```

`apply.sh` leaves the working tree modified. Run `make fdroid-revert` when done
(CI builds in a fresh checkout, so it doesn't need to).

## CI

The `build-android-fdroid` job in `.github/workflows/release.yml` runs on every
release: it applies the swap and uploads `pantry-<version>-fdroid-<abi>.apk`
alongside the normal APKs. Point the F-Droid repository at those `-fdroid`
artifacts, not the default ones. The job builds **one ABI at a time** with
`--target-platform`, the same way the `fdroiddata` recipe builds each
versionCode — see below.

## Reproducible builds

F-Droid verifies our published APK by rebuilding it from source and comparing
byte-for-byte. Three things have to match between the host that publishes the
reference APK (our CI) and the host that rebuilds it (F-Droid):

### 1. Pinned dependencies

`apply.sh` rewrites `pubspec.yaml`, so the default `pubspec.lock` (which tracks
`mobile_scanner`) no longer applies. A plain `flutter pub get` would then
re-resolve `flutter_zxing`'s subtree — `camera_*` and other transitives — to
whatever is newest at build time, so a rebuild weeks later can pick up different
versions than the reference APK and diverge (e.g. a different `flutter_avif`
pulling different bundled assets). To pin it, `tool/fdroid/pubspec.lock` holds
the resolved post-swap lock; `apply.sh` copies it into place and runs
`flutter pub get --enforce-lockfile`.

Regenerate it whenever dependencies change:

```sh
make fdroid-lock   # re-resolves the swapped tree, rewrites tool/fdroid/pubspec.lock
```

Commit the result. `--enforce-lockfile` fails the build loudly if the committed
lock ever drifts from `pubspec.yaml`.

### 2. Identical build command (per-ABI)

The `fdroiddata` recipe builds each ABI as its own versionCode with
`flutter build apk --release --split-per-abi --target-platform=<plat>`. A plain
multi-ABI `--split-per-abi` produces per-APK output that differs from the
isolated per-ABI build, so our CI and `make android-build-apk-fdroid` build the
three ABIs one at a time with the matching `--target-platform`
(`android-arm`, `android-arm64`, `android-x64`), running `flutter clean` between
them to keep each build isolated as F-Droid does.

### 3. Stable native build-ids

The linker stamps each compiled `.so` with a `.note.gnu.build-id` derived from
the pre-strip binary, so host-specific paths in the debug info give the same
code a different build-id on a different machine (#131). `apply.sh` neutralises
this by injecting `--build-id=none` into the link flags of every **source-built**
native lib's CMakeLists — currently `jni` and `flutter_zxing` (the zxing
scanner's `libflutter_zxing.so`). `flutter_avif` ships prebuilt `.so`s in its
`jniLibs`, so it needs no patching.

**Because all three live in `apply.sh` (plus the committed lock and the CI/Make
build commands), the `fdroiddata` recipe stays reproducible only if it runs
`tool/fdroid/apply.sh`** in its `prebuild` (it must run it anyway for the scanner
swap) and builds per-ABI with `--target-platform`. Since these fixes changed
source, F-Droid picks them up only from a **release tag that contains them** —
an older tag rebuilds with its own (unpinned) `apply.sh`.
