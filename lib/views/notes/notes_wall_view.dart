import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/widgets/note_selection_actions.dart';
import 'package:pantry/widgets/note_sort_button.dart';
import 'package:pantry/widgets/note_tile.dart';
import 'package:provider/provider.dart';
import 'note_form_view.dart';
import 'notes_controller.dart';

class NotesWallView extends StatefulWidget {
  final int houseId;

  const NotesWallView({super.key, required this.houseId});

  @override
  State<NotesWallView> createState() => _NotesWallViewState();
}

class _NotesWallViewState extends State<NotesWallView> {
  late final _controller = NotesController(houseId: widget.houseId);

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: const _NotesWallBody(),
    );
  }
}

class _NotesWallBody extends StatelessWidget {
  const _NotesWallBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotesController>();

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

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 4, top: 8, bottom: 8),
              child: Row(
                children: [
                  const Spacer(),
                  if (controller.selectMode)
                    NoteSelectionActions(controller: controller)
                  else ...[
                    IconButton(
                      icon: const Icon(Icons.checklist),
                      tooltip: '',
                      onPressed: controller.toggleSelectMode,
                    ),
                    NoteSortButton(controller: controller),
                  ],
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                child: _NotesGrid(controller: controller),
              ),
            ),
          ],
        ),
        PositionedDirectional(
          end: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _createNote(context, controller),
            child: const Icon(Icons.add),
          ),
        ),
      ],
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

  const _NotesGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    final notes = controller.notes;

    if (notes.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(child: Text(m.notesWall.noNotes)),
        ],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
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
