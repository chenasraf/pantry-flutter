import 'package:flutter/material.dart';
import 'package:pantry/main.dart' show rootScaffoldMessengerKey;

/// Every transient snackbar in the app goes through here.
///
/// As of Flutter 3.38 a `SnackBar` that carries an action defaults to *not*
/// auto-dismissing — it waits for the user. That default is what left the
/// delete/archive undo toasts pinned open indefinitely (issue #100). Passing
/// `persist: false` opts back into duration-based auto-dismissal even with an
/// action present, so the built-in `duration` timer is reliable again and no
/// hand-rolled timer is needed. Routing every snackbar through this one helper
/// keeps the whole app consistent (which is how the bug kept coming back when
/// it was fixed call-site by call-site).
///
/// See: https://docs.flutter.dev/release/breaking-changes/snackbar-with-action-behavior-update
///
/// Shown on the root [ScaffoldMessengerState] via [rootScaffoldMessengerKey] so
/// it survives rebuilds/reparenting of whatever widget triggered it.

/// Shows [message] and auto-dismisses it after [duration]. Pass [action] for an
/// inline button (e.g. Undo). No-op if the root messenger isn't mounted yet.
void showAppSnackBar({
  required String message,
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = rootScaffoldMessengerKey.currentState;
  if (messenger == null) return;
  // Drop any prior snackbar instantly so the new one isn't delayed by the
  // ~250ms exit animation clearSnackBars() would otherwise run.
  messenger.removeCurrentSnackBar(reason: SnackBarClosedReason.remove);
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      action: action,
      // Opt back into auto-dismiss even when an action is present.
      persist: false,
    ),
  );
}

/// Shows an undo snackbar for [message]. Runs [onUndo] when tapped, surfacing
/// [undoFailedMessage] if it throws.
void showUndoSnackBar({
  required String message,
  required String undoLabel,
  required Future<void> Function() onUndo,
  String? undoFailedMessage,
  Duration duration = const Duration(seconds: 6),
}) {
  showAppSnackBar(
    message: message,
    duration: duration,
    action: SnackBarAction(
      label: undoLabel,
      onPressed: () async {
        try {
          await onUndo();
        } catch (_) {
          if (undoFailedMessage != null) {
            showAppSnackBar(message: undoFailedMessage);
          }
        }
      },
    ),
  );
}
