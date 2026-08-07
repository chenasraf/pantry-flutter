import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
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
  /// Restrict decoding to the retail 1D symbologies we resolve — narrower
  /// formats mean fewer false reads and less work per frame.
  static const int _formats =
      Format.ean13 | Format.ean8 | Format.upca | Format.upce;

  /// Fraction of the shorter screen edge used as the (square) decode crop.
  /// Shared between the decoder and the viewfinder border so the box the user
  /// aims at is exactly the region being read.
  static const double _cropPercent = 0.7;

  /// Guards against a second decode racing the pop after the first hit.
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    // Silence flutter_zxing's own per-decode native logging. (The separate
    // "Use dataspace …" spam is an OS camera-surface log we can't disable.)
    zx.setLogEnabled(false);
  }

  void _onScan(Code code) {
    if (_handled) return;
    if (!code.isValid) return;
    final raw = code.text?.trim();
    if (raw != null && BarcodeService.isValidEan(raw)) {
      _finish(raw);
    }
  }

  void _finish(String ean) {
    if (_handled) return;
    _handled = true;
    // ReaderWidget stops and releases the camera on dispose when the route pops.
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
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ReaderWidget(
            onScan: _onScan,
            codeFormat: _formats,
            // tryHarder/tryInverted markedly improve 1D (EAN/UPC) hit rate,
            // which is otherwise unreliable in zxing-cpp. The decoder reads a
            // centered square of [_cropPercent]; we render our viewfinder
            // border through the widget's own overlay hook so it's painted by
            // the same code path as the decode crop and can never drift.
            tryHarder: true,
            tryInverted: true,
            cropPercent: _cropPercent,
            // Our viewfinder: a rounded border + dimmed surround, positioned to
            // match the decoder's crop region (see [_ViewfinderBorder]).
            scannerOverlay: const _ViewfinderBorder(
              cutOutPercent: _cropPercent,
            ),
            showGallery: false,
            showToggleCamera: false,
            actionButtonsAlignment: AlignmentDirectional.topEnd,
            flashOnIcon: const Icon(Icons.flash_on),
            flashOffIcon: const Icon(Icons.flash_off),
            loading: const DecoratedBox(
              decoration: BoxDecoration(color: Colors.black),
            ),
          ),
          // Instruction + manual-entry fallback, clustered at the bottom so
          // they don't cover the centered viewfinder.
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsetsDirectional.all(24),
                  child: Text(
                    b.scanInstructions,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
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

/// Viewfinder overlay for [ReaderWidget]: a rounded border with the surround
/// dimmed for legibility. Passed as the widget's `scannerOverlay` so it renders
/// in place of the built-in corner-bracket overlay, letting us use our own
/// corner radius while keeping the same dimmed look.
class _ViewfinderBorder extends ShapeBorder {
  const _ViewfinderBorder({required this.cutOutPercent});

  /// Cut-out side as a fraction of the shorter edge — must match the widget's
  /// `cropPercent` so the border tracks the decode region.
  final double cutOutPercent;

  static const Color borderColor = Colors.white70;
  static const double borderWidth = 3;
  static const double borderRadius = 12;

  /// Dim applied to everything outside the cut-out, for text legibility.
  static const Color overlayColor = Color(0x73000000); // black ~45%

  Rect _cutOutRect(Rect rect) {
    final side = rect.shortestSide * cutOutPercent;
    // Match flutter_zxing's ScannerOverlayBorder exactly: it positions the
    // cut-out from `rect.width/2, rect.height/2` and ignores `rect.left/top`.
    // Replicating that (rather than using rect.center) keeps our overlay
    // aligned with the decoder's own crop region on every device.
    return Rect.fromLTWH(
      rect.width / 2 - side / 2,
      rect.height / 2 - side / 2,
      side,
      side,
    );
  }

  RRect _cutOutRRect(Rect rect) =>
      RRect.fromRectAndRadius(_cutOutRect(rect), Radius.circular(borderRadius));

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  ShapeBorder scale(double t) => this;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_cutOutRRect(rect));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final cutOut = _cutOutRRect(rect);
    // Dim everything outside the cut-out.
    if (overlayColor.a > 0) {
      final scrim = Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(cutOut),
      );
      canvas.drawPath(scrim, Paint()..color = overlayColor);
    }
    // Border around the cut-out.
    canvas.drawRRect(
      cutOut,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder? a, double t) => this;

  @override
  ShapeBorder lerpTo(ShapeBorder? b, double t) => this;
}
