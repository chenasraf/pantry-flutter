import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Listens for incoming OS-level share intents (photos shared from Photos
/// app, plain text/URL shared from any app, etc.) and exposes the most
/// recent batch via a [ValueListenable]. Consumers should call [consume]
/// after navigating to the share handler so the same payload isn't
/// processed twice.
class ShareIntentService {
  ShareIntentService._();
  static final ShareIntentService instance = ShareIntentService._();

  final ValueNotifier<List<SharedMediaFile>?> pending = ValueNotifier(null);

  StreamSubscription<List<SharedMediaFile>>? _sub;

  /// Begin listening for share intents. Idempotent.
  Future<void> init() async {
    _sub ??= ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) {
        if (files.isNotEmpty) pending.value = files;
      },
      onError: (Object e) {
        debugPrint('[ShareIntentService] stream error: $e');
      },
    );

    final initial = await ReceiveSharingIntent.instance.getInitialMedia();
    if (initial.isNotEmpty) {
      pending.value = initial;
    }
    // Clear the native cache so the same intent isn't re-delivered on
    // subsequent cold starts.
    await ReceiveSharingIntent.instance.reset();
  }

  /// Take the most recent share payload and clear it.
  List<SharedMediaFile>? consume() {
    final v = pending.value;
    pending.value = null;
    return v;
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
