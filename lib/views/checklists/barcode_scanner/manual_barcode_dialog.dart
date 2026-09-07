import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry/services/barcode_service.dart';
import 'package:pantry/views/checklists/barcode_attribution.dart';

/// Manual EAN entry — the always-available fallback when the camera can't or
/// won't scan. Pops the validated digits, or null on cancel.
///
/// Lives outside the swappable scanner implementation so both the ML Kit and
/// flutter_zxing camera scanners share one manual-entry path.
class ManualBarcodeDialog extends StatefulWidget {
  const ManualBarcodeDialog({super.key});

  @override
  State<ManualBarcodeDialog> createState() => _ManualBarcodeDialogState();
}

class _ManualBarcodeDialogState extends State<ManualBarcodeDialog> {
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
