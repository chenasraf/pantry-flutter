import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/note.dart';
import 'package:pantry_core/services/house_service.dart';
import 'package:pantry_core/services/note_service.dart';
import 'package:pantry_core/services/photo_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/sync/sync_ids.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_core/utils/markdown_list.dart';

import '../scope/wear_scope.dart';
import '../services/wear_mirror_client.dart';
import '../widgets/wear_metrics.dart';

/// Everything the notes wall draws, and the one write it can make.
///
/// Notes ride the mirror **whole, bodies included**, so a note is readable on
/// the wrist without a fetch — unlike photos, which carry no bytes at all. The
/// read is still cache-first and never blocking, and it still polls, because
/// the mirror accelerates and never carries: a standalone or out-of-range watch
/// is the same case as a linked one.
///
/// The one write is setting a task line's checkbox. It queues the *change*
/// rather than the document — see [setTaskLine] — and everything read back
/// here has the queue laid over it, so a poll landing between a tick and its
/// drain cannot draw the line back the way it was.
class NotesController extends ChangeNotifier {
  NotesController();

  /// A controller holding a fixed answer, for pumping the real widget tree
  /// without a server. Nothing here polls or subscribes: [start] is what does
  /// that, and a seeded controller is never started.
  @visibleForTesting
  NotesController.seeded({required int houseId, List<Note> notes = const []}) {
    _houseId = houseId;
    _notes = _pinnedFirst(notes);
    _loading = false;
  }

  final _service = NoteService.instance;
  final _sync = SyncManager.instance;
  final _scope = WearScope.instance;
  final _mirror = WearMirrorClient.instance;

  int? _houseId;
  int? get houseId => _houseId;

  List<Note> _notes = const [];

  /// The wall, pinned notes first. The server has already ordered them by the
  /// house's `noteSort`; pinning leads regardless, exactly as it does on the
  /// phone's wall.
  List<Note> get notes => _notes;

  String _sortBy = 'custom';

  bool _loading = true;
  bool get isLoading => _loading;

  /// True when there is nothing to scope to — no house the wearer can see.
  bool get hasNoScope => _houseId == null;

  /// The last write the server refused, for the page to say so. The row itself
  /// needs no putting back: it was only ever drawn by the queue overlay, which
  /// a dropped op leaves.
  String? _dropped;
  String? get droppedMessage => _dropped;
  void clearDropped() {
    if (_dropped == null) return;
    _dropped = null;
    _emit();
  }

  bool _active = false;
  bool _disposed = false;
  Timer? _poll;
  StreamSubscription<SyncOpApplied>? _applied;
  StreamSubscription<SyncOpSkipped>? _skipped;

  Future<void> start() async {
    _applied ??= _sync.onApplied.listen(_onApplied);
    _skipped ??= _sync.onSkipped.listen(_onSkipped);
    _scope.addListener(_onScopeChanged);
    _mirror.addListener(_onMirrored);
    await _loadFromCache();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    _applied?.cancel();
    _skipped?.cancel();
    _scope.removeListener(_onScopeChanged);
    _mirror.removeListener(_onMirrored);
    super.dispose();
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  /// Only a page on screen polls. A Dart timer keeps firing while the watch
  /// sleeps — measured at 219 ticks through one doze window — so pausing is
  /// what stops the app draining the battery in a pocket, not an optimisation.
  void setActive(bool active) {
    if (_active == active) return;
    _active = active;
    if (active) {
      _schedulePoll();
      unawaited(_mirror.requestMirror());
      unawaited(refresh());
    } else {
      _poll?.cancel();
      _poll = null;
    }
  }

  void _schedulePoll() {
    _poll?.cancel();
    if (!_active) return;
    final interval = pollInterval;
    if (interval == null) return;
    _poll = Timer.periodic(interval, (_) => unawaited(refresh()));
  }

  /// How often to re-read, or null when the wearer has turned polling off.
  /// Stretched while snapshots are arriving and never stopped, exactly as the
  /// checklists page reads.
  Duration? get pollInterval {
    final seconds = PrefsService.instance.wearPollSeconds;
    if (seconds <= 0) return null;
    final landed = _mirror.landedAt;
    final fresh =
        landed != null &&
        DateTime.now().difference(landed) < WearMetrics.mirrorFreshFor;
    return Duration(seconds: seconds * (fresh ? WearMetrics.pollStretch : 1));
  }

  /// A snapshot landed in the cache this page reads, so re-read it. The same
  /// read a poll would have done, arriving without the request.
  void _onMirrored() {
    _schedulePoll();
    unawaited(_loadFromCache());
  }

  void _onScopeChanged() {
    unawaited(_loadFromCache().then((_) => refresh()));
  }

  // -- Reading ---------------------------------------------------------------

  /// Everything the watch can answer without the network, so the wall draws
  /// immediately with whatever the last session left behind.
  Future<void> _loadFromCache() async {
    final houses = HouseService.instance.getCached() ?? const [];
    _houseId = await _scope.resolveHouse(houses) ?? _scope.houseId;
    final house = _houseId;
    if (house == null) {
      _loading = false;
      _emit();
      return;
    }
    _sortBy = _service.cachedSortBy(house);
    _notes = _pinnedFirst(_service.getCachedNotes(house) ?? _notes);
    _loading = false;
    _emit();
  }

  /// One pass over the wall. Nothing here throws: a failed leg leaves the
  /// cached answer in place and the next poll tries again.
  Future<void> refresh() async {
    final house = _houseId;
    if (house == null) return;
    await _refreshSort(house);
    try {
      final fetched = await _service.getNotes(house, sortBy: _sortBy);
      _service.cacheNotes(house, fetched);
      _notes = _pinnedFirst(fetched);
    } catch (_) {
      // The wall the watch last knew is a better wall than an empty one.
    }
    _loading = false;
    _emit();
  }

  /// Sort order is a house pref, so it arrives the way the checklist's
  /// grouping does and means the same thing on every device. A failed read
  /// leaves the cached answer in place.
  Future<void> _refreshSort(int house) async {
    try {
      final prefs = await PhotoService.instance.getHousePrefs(house);
      _sortBy = prefs['noteSort'] as String? ?? 'custom';
      _service.setCachedSortBy(house, _sortBy);
    } catch (_) {}
  }

  static List<Note> _pinnedFirst(List<Note> notes) => [
    for (final n in notes)
      if (n.isPinned) n,
    for (final n in notes)
      if (!n.isPinned) n,
  ];

  /// [note]'s body as the wearer should see it: what the last snapshot said,
  /// with every tick still waiting in the queue laid back over it.
  ///
  /// The queue wins over any snapshot, from any source. Without this a poll
  /// landing between a tick and its drain — or simply a relaunch — would draw
  /// the line the way it was before the wearer touched it.
  String? bodyOf(Note note) {
    final house = _houseId;
    if (house == null) return note.content;
    return _sync.pendingNoteContent(house, note.id, note.content);
  }

  /// What a wall card says instead of a preview, once ticking is the only
  /// write: how much of this note is left.
  ({int done, int total}) progressOf(Note note) {
    final lines = taskLines(bodyOf(note) ?? '');
    var done = 0;
    for (final line in lines) {
      if (line.checked) done++;
    }
    return (done: done, total: lines.length);
  }

  // -- Writing ---------------------------------------------------------------

  /// Set the task line at [ordinal] — reading [text] — to [checked].
  ///
  /// Queued as the change rather than the rewritten body. A whole-document
  /// write is one the server cannot arbitrate: held behind an offline spell it
  /// drains as "set this note's body to what my cache said", answering 200
  /// while silently reverting whatever was edited on the phone or the web in
  /// the window. [text] rides along so the write follows its line when another
  /// is inserted above it.
  ///
  /// A tick on a line already in that state queues nothing at all.
  void setTaskLine(
    Note note, {
    required int ordinal,
    required String text,
    required bool checked,
  }) {
    final house = _houseId;
    final content = bodyOf(note);
    if (house == null || content == null) return;
    if (setChecklistItem(content, ordinal, checked) == content) return;

    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.note,
        op: SyncOpKind.toggle,
        houseId: house,
        entityId: note.id < 0 ? null : note.id,
        tempEntityId: note.id < 0 ? note.id : null,
        body: {'ordinal': ordinal, 'text': text, 'checked': checked},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    // The op is now part of every read, so the row already draws its new
    // state — the overlay is the optimistic update.
    _emit();
  }

  // -- Reconciling with the queue -------------------------------------------

  void _onApplied(SyncOpApplied event) {
    if (event.op.houseId != _houseId) return;
    if (event.op.entity != SyncEntity.note) return;
    unawaited(refresh());
  }

  /// A dropped op is the one case the wearer has to be told about: the server
  /// refused the write, so the state they saw was never true. The row goes
  /// back on its own — it was the queue drawing it.
  void _onSkipped(SyncOpSkipped event) {
    if (event.op.houseId != _houseId) return;
    if (event.op.entity != SyncEntity.note) return;
    _dropped = m.sync.syncError;
    unawaited(refresh());
  }
}
