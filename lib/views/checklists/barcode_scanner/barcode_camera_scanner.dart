import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry/services/barcode_service.dart';
import 'package:pantry/views/checklists/barcode_attribution.dart';
import 'package:pantry/views/checklists/barcode_scanner/manual_barcode_dialog.dart';

/// Full-screen camera barcode scanner backed by Google ML Kit
/// (`mobile_scanner`). Pops the decoded digits of the first EAN/UPC it sees
/// (or a manually-typed number), or null if dismissed.
///
/// This is the default implementation, used by every store build for the best
/// scan quality. The F-Droid build swaps this file for the FLOSS flutter_zxing
/// implementation in `fdroid/barcode_camera_scanner.dart` (see fdroid/README.md).
/// Keep the public surface — [BarcodeCameraScanner], its const constructor, and
/// the popped `String?` result — identical across both.
class BarcodeCameraScanner extends StatefulWidget {
  const BarcodeCameraScanner({super.key});

  @override
  State<BarcodeCameraScanner> createState() => _BarcodeCameraScannerState();
}

class _BarcodeCameraScannerState extends State<BarcodeCameraScanner> {
  late final MobileScannerController _controller = MobileScannerController(
    // A physical scan fires many frames; noDuplicates + our own guard keep it
    // to a single result.
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );

  /// Guards against a second decode racing the pop after the first hit.
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && BarcodeService.isValidEan(raw)) {
        _finish(raw);
        return;
      }
    }
  }

  void _finish(String ean) {
    if (_handled) return;
    _handled = true;
    _controller.stop();
    if (mounted) Navigator.of(context).pop(ean);
  }

  Future<void> _enterManually() async {
    final ean = await showDialog<String>(
      context: context,
      builder: (_) => const ManualBarcodeDialog(),
    );
    if (ean != null) _finish(ean);
  }

  @override
  Widget build(BuildContext context) {
    final b = m.checklists.barcode;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(b.scanTitle),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: b.torch,
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Dim frame + instruction + manual-entry fallback.
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const SizedBox(width: 260, height: 160),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.all(24),
                  child: Text(
                    b.scanInstructions,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _enterManually,
                  icon: const Icon(Icons.keyboard, color: Colors.white),
                  label: Text(
                    b.enterManually,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
                  child: BarcodeAttribution(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
