import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/models/note.dart';
import 'package:pantry_core/services/note_service.dart';
import 'package:pantry_core/services/pending_note_share_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry/utils/app_toast.dart';
import 'package:pantry/widgets/auto_refresh.dart';
import 'package:pantry/widgets/note_selection_actions.dart';
import 'package:pantry/widgets/note_sort_button.dart';
import 'package:pantry/widgets/note_tile.dart';
import 'package:pantry/views/home/home_floating_nav.dart';
import 'package:provider/provider.dart';
import 'note_detail_view.dart';
import 'note_form_view.dart';
import 'notes_controller.dart';

class NotesWallView extends StatefulWidget {
  final int houseId;
  final ValueNotifier<Future<void> Function()?>? refreshHolder;

  /// Vertical scroll controller for the notes grid. Owned by the host so iOS
  /// status-bar-tap can scroll this tab to the top.
  final ScrollController? scrollController;

  /// Slot for the action this tab contributes to the home floating nav's
  /// trailing button.
  final ValueNotifier<NavPrimaryAction?>? navActionHolder;

  const NotesWallView({
    super.key,
    required this.houseId,
    this.refreshHolder,
    this.scrollController,
    this.navActionHolder,
  });

  @override
  State<NotesWallView> createState() => _NotesWallViewState();
}

class _NotesWallViewState extends State<NotesWallView> {
  late final _controller = NotesController(houseId: widget.houseId);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_maybeOpenPendingNote);
    _controller.load();
    final holder = widget.refreshHolder;
    if (holder != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        holder.value = _controller.refresh;
      });
    }
    PendingNoteShareService.instance.addListener(_handlePendingShare);
    // Drop whatever the previous wall left in the nav slot. An offer from this
    // one looks identical and would be discarded as unchanged, leaving the
    // button wired to a wall that is gone.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.navActionHolder?.value = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingShare());
  }

  @override
  void dispose() {
    if (widget.refreshHolder?.value == _controller.refresh) {
      widget.refreshHolder?.value = null;
    }
    PendingNoteShareService.instance.removeListener(_handlePendingShare);
    _controller.removeListener(_maybeOpenPendingNote);
    _controller.dispose();
    super.dispose();
  }

  /// Consume a pending note deep link: once the wall is loaded, open that
  /// note. Cleared whether or not the note is found, so a stale request can't
  /// reopen on a later load.
  void _maybeOpenPendingNote() {
    final id = NoteService.instance.pendingOpenNoteId;
    if (id == null || !mounted || _controller.isLoading) return;
    NoteService.instance.pendingOpenNoteId = null;
    final note = _controller.notes.cast<Note?>().firstWhere(
      (n) => n!.id == id,
      orElse: () => null,
    );
    if (note == null) return;
    // Off the notification, not into it: the wall may be mid-rebuild when the
    // load that answered the link lands.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final colours = noteColours(note, Theme.of(context));
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NoteDetailView(
            note: note,
            controller: _controller,
            bgColor: colours.ground,
            textColor: colours.ink,
          ),
        ),
      );
    });
  }

  void _handlePendingShare() {
    final share = PendingNoteShareService.instance.takeForHouse(widget.houseId);
    if (share == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteFormView(
          controller: _controller,
          prefillContent: share.content,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep the controller's view of house capabilities fresh; descendants gate
    // off `controller.permissions`.
    _controller.permissions = context.watch<HousePermissions>();
    return ChangeNotifierProvider.value(
      value: _controller,
      child: _NotesWallBody(
        scrollController: widget.scrollController,
        navActionHolder: widget.navActionHolder,
      ),
    );
  }
}

class _NotesWallBody extends StatelessWidget {
  final ScrollController? scrollController;
  final ValueNotifier<NavPrimaryAction?>? navActionHolder;

  const _NotesWallBody({this.scrollController, this.navActionHolder});

  /// Hand the nav bar the wall's primary action. Deferred a frame so a
  /// listenable isn't mutated mid-build.
  void _publishNavAction(BuildContext context, NotesController controller) {
    final holder = navActionHolder;
    if (holder == null) return;
    final offer =
        !controller.isTrashMode && controller.permissions.canCreateNotes
        ? NavPrimaryAction(
            icon: Icons.add,
            label: m.notesWall.newNote,
            onTap: () => _createNote(context, controller),
          )
        : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      holder.value = offer;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotesController>();
    final prefs = context.watch<PrefsService>();
    _publishNavAction(context, controller);

    if (controller.isLoading && controller.notes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null && controller.notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(controller.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.load,
                child: Text(m.common.retry),
              ),
            ],
          ),
        ),
      );
    }

    final inTrash = controller.isTrashMode;

    return AutoRefresh(
      interval: AutoRefresh.durationFromSeconds(prefs.notesRefreshSeconds),
      onRefresh: () =>
          inTrash ? controller.refreshTrash() : controller.refresh(),
      child: PopScope(
        canPop: !inTrash,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (controller.isTrashMode) controller.setTrashMode(false);
        },
        child: Stack(
          children: [
            Column(
              children: [
                if (inTrash)
                  _TrashBanner(controller: controller)
                else
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: 4,
                      top: 8,
                      bottom: 8,
                    ),
                    child: Row(
                      children: [
                        const Spacer(),
                        if (controller.selectMode)
                          NoteSelectionActions(controller: controller)
                        else ...[
                          // Selection mode only enables bulk delete.
                          if (controller.permissions.canDeleteNotes)
                            IconButton(
                              icon: const Icon(Icons.checklist),
                              tooltip: '',
                              onPressed: controller.toggleSelectMode,
                            ),
                          NoteSortButton(controller: controller),
                          if (hasFeature('note-trash') &&
                              controller.permissions.canDeleteNotes)
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: m.notesWall.viewTrash,
                              onPressed: () => controller.setTrashMode(true),
                            ),
                        ],
                      ],
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: inTrash
                        ? controller.refreshTrash
                        : controller.refresh,
                    child: inTrash
                        ? _TrashGrid(
                            controller: controller,
                            scrollController: scrollController,
                          )
                        : _NotesGrid(
                            controller: controller,
                            scrollController: scrollController,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _createNote(BuildContext context, NotesController controller) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NoteFormView(controller: controller)),
    );
  }
}

class _NotesGrid extends StatelessWidget {
  final NotesController controller;
  final ScrollController? scrollController;

  const _NotesGrid({required this.controller, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final notes = controller.notes;

    if (notes.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Center(child: Text(m.notesWall.noNotes)),
        ],
      );
    }

    return GridView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      // Trailing room for the floating nav the grid scrolls under.
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: notes.length + (controller.draggingId != null ? 0 : 0),
      itemBuilder: (context, index) {
        final note = notes[index];
        if (note.id == controller.draggingId) {
          // Placeholder for the dragged note
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
            ),
          );
        }
        return NoteTile(note: note, controller: controller);
      },
    );
  }
}

class _TrashBanner extends StatelessWidget {
  final NotesController controller;

  const _TrashBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
      child: Row(
        children: [
          Icon(Icons.delete_outline, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              m.notesWall.trashTitle,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          if (controller.trashed.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmEmptyTrash(context, controller),
              icon: const Icon(Icons.delete_forever, size: 16),
              label: Text(m.notesWall.emptyTrash),
            ),
          TextButton.icon(
            onPressed: () => controller.setTrashMode(false),
            icon: const Icon(Icons.close, size: 16),
            label: Text(m.notesWall.exitTrash),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmEmptyTrash(
    BuildContext context,
    NotesController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.notesWall.emptyTrashConfirm),
        content: Text(m.notesWall.emptyTrashConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.notesWall.emptyTrash),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await controller.emptyTrash();
    } catch (_) {
      if (context.mounted) {
        showAppToast(
          message: m.notesWall.emptyTrashFailed,
          kind: ToastKind.error,
        );
      }
    }
  }
}

class _TrashGrid extends StatelessWidget {
  final NotesController controller;
  final ScrollController? scrollController;

  const _TrashGrid({required this.controller, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final notes = controller.trashed;
    if (notes.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Center(
            child: Text(
              m.notesWall.trashEmpty,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }
    return GridView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _TrashedNoteTile(note: note, controller: controller);
      },
    );
  }
}

class _TrashedNoteTile extends StatelessWidget {
  final Note note;
  final NotesController controller;

  const _TrashedNoteTile({required this.note, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = _parseColor(note.color) ?? cs.surfaceContainerHighest;
    final textColor = bgColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;

    return GestureDetector(
      onTap: () => _showTrashActions(context),
      child: Opacity(
        opacity: 0.65,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.delete_outline, color: textColor, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      note.title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (note.content != null && note.content!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    note.content!,
                    style: TextStyle(color: textColor, fontSize: 12),
                    overflow: TextOverflow.fade,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var h = hex.replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    return v != null ? Color(v) : null;
  }

  Future<void> _showTrashActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restore_from_trash),
              title: Text(m.notesWall.restore),
              onTap: () => Navigator.pop(ctx, 'restore'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: Text(m.notesWall.permanentlyDelete),
              onTap: () => Navigator.pop(ctx, 'permanent'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    if (action == 'restore') {
      try {
        await controller.restoreNote(note);
      } catch (_) {
        if (context.mounted) {
          showAppToast(
            message: m.notesWall.restoreFailed,
            kind: ToastKind.error,
          );
        }
      }
    } else if (action == 'permanent') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(m.notesWall.permanentlyDeleteConfirm),
          content: Text(m.notesWall.permanentlyDeleteConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(m.common.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(m.notesWall.permanentlyDelete),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      try {
        await controller.permanentlyDeleteNote(note);
      } catch (_) {
        if (context.mounted) {
          showAppToast(
            message: m.notesWall.deleteFailed,
            kind: ToastKind.error,
          );
        }
      }
    }
  }
}
