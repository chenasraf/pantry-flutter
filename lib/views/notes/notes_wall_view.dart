import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/note.dart';
import 'package:provider/provider.dart';
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
                  _SortButton(controller: controller),
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
        Positioned(
          right: 16,
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
      MaterialPageRoute(builder: (_) => _NoteFormPage(controller: controller)),
    );
  }
}

class _SortButton extends StatelessWidget {
  final NotesController controller;

  const _SortButton({required this.controller});

  static const _sortKeys = [
    'newest',
    'oldest',
    'title_asc',
    'title_desc',
    'custom',
  ];

  static String _label(String key) => switch (key) {
    'newest' => m.notesWall.sort.newestFirst,
    'oldest' => m.notesWall.sort.oldestFirst,
    'title_asc' => m.notesWall.sort.titleAZ,
    'title_desc' => m.notesWall.sort.titleZA,
    'custom' => m.notesWall.sort.custom,
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      tooltip: '',
      onSelected: controller.setSortBy,
      itemBuilder: (context) => [
        for (final key in _sortKeys)
          PopupMenuItem<String>(
            value: key,
            child: Row(
              children: [
                Icon(
                  key == controller.sortBy
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: key == controller.sortBy
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 12),
                Text(_label(key)),
              ],
            ),
          ),
      ],
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
      padding: const EdgeInsets.all(8),
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
        return _NoteTile(note: note, controller: controller);
      },
    );
  }
}

class _NoteTile extends StatelessWidget {
  final Note note;
  final NotesController controller;

  const _NoteTile({required this.note, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor =
        _parseColor(note.color) ?? theme.colorScheme.surfaceContainerHighest;
    final textColor = _contrastColor(bgColor);

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != note.id,
      onAcceptWithDetails: (_) {},
      onMove: (_) => controller.hoverReorder(note.id),
      builder: (context, _, _) {
        return LongPressDraggable<int>(
          data: note.id,
          onDragStarted: () => controller.startDrag(note.id),
          onDragEnd: (_) => controller.endDrag(),
          onDraggableCanceled: (_, _) => controller.cancelDrag(),
          feedback: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 160,
              height: 160,
              child: _buildCard(theme, bgColor, textColor),
            ),
          ),
          child: GestureDetector(
            onTap: () => _viewNote(context, bgColor, textColor),
            child: _buildCard(theme, bgColor, textColor),
          ),
        );
      },
    );
  }

  Widget _buildCard(ThemeData theme, Color bgColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _NoteMenuButton(
                note: note,
                controller: controller,
                color: textColor,
              ),
            ],
          ),
          if (note.content != null && note.content!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                note.content!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withAlpha(200),
                ),
                overflow: TextOverflow.fade,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _viewNote(BuildContext context, Color bgColor, Color textColor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NoteDetailPage(
          note: note,
          controller: controller,
          bgColor: bgColor,
          textColor: textColor,
        ),
      ),
    );
  }

  static Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.tryParse(hex, radix: 16);
    return value != null ? Color(value) : null;
  }

  static Color _contrastColor(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

class _NoteMenuButton extends StatelessWidget {
  final Note note;
  final NotesController controller;
  final Color color;

  const _NoteMenuButton({
    required this.note,
    required this.controller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 20, color: color),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _editNote(context);
          case 'delete':
            _confirmDelete(context);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 18),
              const SizedBox(width: 8),
              Text(m.notesWall.editNote),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 18),
              const SizedBox(width: 8),
              Text(m.common.delete),
            ],
          ),
        ),
      ],
    );
  }

  void _editNote(BuildContext context) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _NoteFormPage(controller: controller, note: note),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.notesWall.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteNote(note);
            },
            child: Text(m.common.delete),
          ),
        ],
      ),
    );
  }
}

// -- Note form (add / edit) --

const _colorOptions = [
  null, // default / no color
  '#FFEB3B', // yellow
  '#4CAF50', // green
  '#2196F3', // blue
  '#9C27B0', // purple
  '#F44336', // red
  '#FF9800', // orange
  '#00BCD4', // teal
  '#E91E63', // pink
  '#8BC34A', // light green
];

class _NoteDetailPage extends StatelessWidget {
  final Note note;
  final NotesController controller;
  final Color bgColor;
  final Color textColor;

  const _NoteDetailPage({
    required this.note,
    required this.controller,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        title: Text(note.title),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => _NoteFormPage(controller: controller, note: note),
            ),
          );
        },
        child: const Icon(Icons.edit),
      ),
      body: note.content != null && note.content!.isNotEmpty
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                note.content!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: textColor.withAlpha(220),
                ),
              ),
            )
          : null,
    );
  }
}

class _NoteFormPage extends StatefulWidget {
  final NotesController controller;
  final Note? note;

  const _NoteFormPage({required this.controller, this.note});

  @override
  State<_NoteFormPage> createState() => _NoteFormPageState();
}

class _NoteFormPageState extends State<_NoteFormPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  String? _selectedColor;
  bool _saving = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _selectedColor = widget.note?.color;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await widget.controller.updateNote(
          widget.note!,
          title: title,
          content: _contentController.text,
          color: _selectedColor ?? '',
        );
      } else {
        await widget.controller.addNote(
          title: title,
          content: _contentController.text,
          color: _selectedColor,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.notesWall.saveFailed)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? m.notesWall.editNote : m.notesWall.newNote),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: m.notesWall.title,
              border: const OutlineInputBorder(),
            ),
            autofocus: !_isEditing,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            decoration: InputDecoration(
              labelText: m.notesWall.content,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 10,
            minLines: 4,
          ),
          const SizedBox(height: 16),
          Text(
            m.notesWall.color,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colorOptions.map((hex) {
              final color = hex != null
                  ? Color(
                      int.parse('FF${hex.replaceFirst('#', '')}', radix: 16),
                    )
                  : Theme.of(context).colorScheme.surfaceContainerHighest;
              final isSelected = _selectedColor == hex;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = hex),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          )
                        : Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 18,
                          color: _contrastColor(color),
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static Color _contrastColor(Color bg) {
    return bg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  }
}
