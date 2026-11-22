import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/note.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry/utils/app_toast.dart';
import 'package:pantry/views/notes/nextcloud_file_picker.dart';
import 'package:pantry/views/notes/notes_controller.dart';

/// Whether [note] can be bound to a file or unbound from one. A note still
/// waiting in the queue has no server id for the endpoint to address.
bool canChangeNoteFileSync(NotesController controller, Note note) =>
    ServerFeature.noteFileSync &&
    note.id > 0 &&
    note.canEditWith(controller.permissions.canUpdateNotes);

bool canImportNoteFromFile(NotesController controller) =>
    ServerFeature.noteFileSync && controller.permissions.canCreateNotes;

/// The server's own words when it gave any — "already synced", "not a
/// writable folder" — since those tell the user what to change.
String _failure(Object error, String fallback) =>
    (error is ApiException && error is! OfflineException
        ? error.serverMessage
        : null) ??
    fallback;

/// Asks for a folder and binds [note] to a new file in it. Returns the updated
/// note, or null when nothing changed.
Future<Note?> startNoteFileSync(
  BuildContext context,
  NotesController controller,
  Note note,
) async {
  final folder = await pickNextcloudPath(
    context,
    mode: NextcloudPickMode.folder,
  );
  if (folder == null) return null;
  try {
    final updated = await controller.startFileSync(note, folder);
    showAppToast(
      message: m.notesWall.syncingWith(updated.syncDisplayPath ?? folder),
    );
    return updated;
  } catch (e) {
    debugPrint('[NoteFileSync] Start failed: $e');
    showAppToast(
      message: _failure(e, m.notesWall.startFileSyncFailed),
      kind: ToastKind.error,
    );
    return null;
  }
}

/// Confirms, then unbinds [note] from its file. Returns the updated note, or
/// null when nothing changed.
Future<Note?> stopNoteFileSync(
  BuildContext context,
  NotesController controller,
  Note note,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(m.notesWall.stopFileSyncConfirm),
      content: Text(m.notesWall.stopFileSyncConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(m.common.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(m.notesWall.stopFileSync),
        ),
      ],
    ),
  );
  if (confirmed != true) return null;
  try {
    final updated = await controller.stopFileSync(note);
    showAppToast(message: m.notesWall.fileSyncStopped);
    return updated;
  } catch (e) {
    debugPrint('[NoteFileSync] Stop failed: $e');
    showAppToast(
      message: _failure(e, m.notesWall.stopFileSyncFailed),
      kind: ToastKind.error,
    );
    return null;
  }
}

/// Asks for a text file and makes a note of it, kept in sync with the file.
Future<void> importNoteFromFile(
  BuildContext context,
  NotesController controller,
) async {
  final path = await pickNextcloudPath(
    context,
    mode: NextcloudPickMode.noteFile,
  );
  if (path == null) return;
  try {
    final note = await controller.importFromFile(path);
    showAppToast(message: m.notesWall.importedNote(note.title));
  } catch (e) {
    debugPrint('[NoteFileSync] Import failed: $e');
    showAppToast(
      message: _failure(e, m.notesWall.importFromFileFailed),
      kind: ToastKind.error,
    );
  }
}
