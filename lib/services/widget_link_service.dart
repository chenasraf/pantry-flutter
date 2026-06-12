import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Receives taps from the Pantry home-screen widget and broadcasts the
/// target list + house IDs so the home view can navigate accordingly.
class WidgetLinkService {
  WidgetLinkService._();
  static final WidgetLinkService instance = WidgetLinkService._();

  static const _channel = MethodChannel('dev.casraf.pantry/widget');

  final ValueNotifier<WidgetTap?> pending = ValueNotifier(null);

  void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetTap') {
        await _fetchPending();
      }
    });
  }

  Future<void> checkOnResume() => _fetchPending();

  Future<void> _fetchPending() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getPendingWidgetTap',
      );
      if (result != null) {
        pending.value = WidgetTap(
          listId: result['listId'] as int,
          houseId: result['houseId'] as int?,
        );
      }
    } catch (_) {}
  }
}

class WidgetTap {
  final int listId;
  final int? houseId;
  const WidgetTap({required this.listId, this.houseId});
}
