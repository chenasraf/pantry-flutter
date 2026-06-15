import 'dart:async';
import 'package:flutter/material.dart';

/// Pinning the 6s dismissal to an explicit timer instead of `SnackBar.duration`.
///
/// SnackBar's internal duration timer gets reset whenever its MediaQuery
/// dependency rebuilds — frequent on list/grid views during background polls
/// and animation ticks. The explicit timer here ignores rebuilds and closes
/// the snackbar exactly once.
Timer? _undoTimer;

void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required String undoLabel,
  required Future<void> Function() onUndo,
  String? undoFailedMessage,
  Duration duration = const Duration(seconds: 6),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.removeCurrentSnackBar(reason: SnackBarClosedReason.remove);
  _undoTimer?.cancel();
  final entry = messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      action: SnackBarAction(
        label: undoLabel,
        onPressed: () async {
          _undoTimer?.cancel();
          try {
            await onUndo();
          } catch (_) {
            if (undoFailedMessage != null && context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(undoFailedMessage)));
            }
          }
        },
      ),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _undoTimer = Timer(duration, entry.close);
  });
}
