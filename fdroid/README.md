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
artifacts, not the default ones.
