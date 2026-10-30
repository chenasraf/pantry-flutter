import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry/utils/app_toast.dart';

/// Whether this member gets the daily stock summaries of the house in view. A
/// per-house pref, hidden until the server answers, since a guess would show
/// the wrong choice.
class StockSummaryTile extends StatefulWidget {
  final int houseId;

  const StockSummaryTile({super.key, required this.houseId});

  @override
  State<StockSummaryTile> createState() => _StockSummaryTileState();
}

class _StockSummaryTileState extends State<StockSummaryTile> {
  bool? _value;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await ChecklistService.instance.getStockSummaryPref(
        widget.houseId,
      );
      if (mounted) setState(() => _value = value);
    } catch (e) {
      debugPrint('[StockSummaryTile] Failed to load: $e');
    }
  }

  Future<void> _set(bool value) async {
    final previous = _value;
    setState(() => _value = value);
    try {
      await ChecklistService.instance.setStockSummaryPref(
        widget.houseId,
        value,
      );
    } catch (e) {
      debugPrint('[StockSummaryTile] Failed to save: $e');
      showAppToast(message: m.stock.summaryPrefFailed, kind: ToastKind.error);
      if (mounted) setState(() => _value = previous);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = _value;
    if (value == null) return const SizedBox.shrink();
    return SwitchListTile(
      secondary: const Icon(Icons.inventory_2_outlined),
      title: Text(m.stock.summaryPref),
      subtitle: Text(m.stock.summaryPrefHint),
      value: value,
      onChanged: _set,
    );
  }
}
