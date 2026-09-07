import 'package:flutter/material.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry/views/checklists/barcode_scanner/barcode_camera_scanner.dart';
import 'package:pantry/views/checklists/barcode_scanner/manual_barcode_dialog.dart';

/// Entry point for barcode capture. Resolves to the decoded digits of a
/// scanned or manually-typed EAN/UPC, or null if dismissed.
///
/// Push it with [BarcodeScanView.scan], which returns the scanned EAN so the
/// caller can run the cache lookup / external resolve / prepopulate flow.
///
/// The camera scanner itself is [BarcodeCameraScanner], whose implementation is
/// swapped at build time: the default build uses Google ML Kit
/// (`mobile_scanner`) for the best scan quality, while the F-Droid build
/// substitutes the FLOSS `flutter_zxing` so the APK carries no proprietary
/// code. See fdroid/README.md.
abstract final class BarcodeScanView {
  /// Returns a barcode to look up, or null if the user backed out.
  ///
  /// Camera scanning is a mobile-only affordance — desktop and web have no
  /// reliable camera path, so there it goes straight to the manual-entry
  /// dialog instead of opening the (cameraless) scanner.
  static Future<String?> scan(BuildContext context) {
    if (!PlatformInfo.isMobile) {
      return showDialog<String>(
        context: context,
        builder: (_) => const ManualBarcodeDialog(),
      );
    }
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const BarcodeCameraScanner(),
      ),
    );
  }
}
