import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/services/barcode_service.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/views/checklists/barcode_attribution.dart';

/// Full-screen camera barcode scanner. Resolves to the decoded digits of the
/// first EAN/UPC it sees (or a manually-typed number), or null if dismissed.
///
/// Push it with [BarcodeScanView.scan], which returns the scanned EAN so the
/// caller can run the cache lookup / external resolve / prepopulate flow.
class BarcodeScanView extends StatefulWidget {
  const BarcodeScanView({super.key});

  /// Returns a barcode to look up, or null if the user backed out.
  ///
  /// Camera scanning is a mobile-only affordance — desktop and web have no
  /// reliable camera path, so there it goes straight to the manual-entry
  /// dialog instead of opening the (cameraless) scanner.
  static Future<String?> scan(BuildContext context) {
    if (!PlatformInfo.isMobile) {
      return showDialog<String>(
        context: context,
        builder: (_) => const _ManualBarcodeDialog(),
      );
    }
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const BarcodeScanView(),
      ),
    );
  }

  @override
  State<BarcodeScanView> createState() => _BarcodeScanViewState();
}

class _BarcodeScanViewState extends State<BarcodeScanView> {
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
      builder: (_) => const _ManualBarcodeDialog(),
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

/// Manual EAN entry — the always-available fallback when the camera can't or
/// won't scan. Pops the validated digits, or null on cancel.
class _ManualBarcodeDialog extends StatefulWidget {
  const _ManualBarcodeDialog();

  @override
  State<_ManualBarcodeDialog> createState() => _ManualBarcodeDialogState();
}

class _ManualBarcodeDialogState extends State<_ManualBarcodeDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final ean = _controller.text.trim();
    if (!BarcodeService.isValidEan(ean)) {
      setState(() => _error = m.checklists.barcode.invalidBarcode);
      return;
    }
    Navigator.of(context).pop(ean);
  }

  @override
  Widget build(BuildContext context) {
    final b = m.checklists.barcode;
    return AlertDialog(
      title: Text(b.manualTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: b.manualHint,
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          const BarcodeAttribution(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(m.common.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(b.scan)),
      ],
    );
  }
}
