import 'package:flutter/foundation.dart';

/// A pending note to be created from an OS share intent. Held until the
/// notes wall picks it up and opens the new-note form prefilled.
class PendingNoteShare {
  final int houseId;
  final String content;

  const PendingNoteShare({required this.houseId, required this.content});
}

/// Cross-screen signal carrying a pending note share. The share router
/// pushes here, then asks the home view to switch to the notes tab; the
/// [NotesWallView] for the same house listens and opens the form.
class PendingNoteShareService extends ChangeNotifier {
  PendingNoteShareService._();
  static final PendingNoteShareService instance = PendingNoteShareService._();

  PendingNoteShare? _pending;
  PendingNoteShare? get pending => _pending;

  void push(PendingNoteShare share) {
    _pending = share;
    notifyListeners();
  }

  /// Returns the pending share if it matches [houseId] and clears it.
  PendingNoteShare? takeForHouse(int houseId) {
    if (_pending?.houseId != houseId) return null;
    final taken = _pending;
    _pending = null;
    return taken;
  }
}
