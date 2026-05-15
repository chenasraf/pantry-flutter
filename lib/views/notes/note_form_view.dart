import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/note.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/views/notes/notes_controller.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';

const _colorOptions = <String?>[
  null, // default / no color
  '#f44336', // red
  '#e91e63', // pink
  '#9c27b0', // purple
  '#673ab7', // deep purple
  '#3f51b5', // indigo
  '#2196f3', // blue
  '#03a9f4', // light blue
  '#00bcd4', // cyan
  '#009688', // teal
  '#4caf50', // green
  '#8bc34a', // light green
  '#cddc39', // lime
  '#ffeb3b', // yellow
  '#ffc107', // amber
  '#ff9800', // orange
  '#ff5722', // deep orange
];

class NoteFormView extends StatefulWidget {
  final NotesController controller;
  final Note? note;

  /// When opening a new note seeded from an OS share intent, this holds
  /// the shared text/URL to prefill into the content field.
  final String? prefillContent;

  const NoteFormView({
    super.key,
    required this.controller,
    this.note,
    this.prefillContent,
  });

  @override
  State<NoteFormView> createState() => _NoteFormViewState();
}

class _NoteFormViewState extends State<NoteFormView> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  String? _selectedColor;
  bool _saving = false;
  TextDirection _titleDir = TextDirection.ltr;
  TextDirection _contentDir = TextDirection.ltr;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? widget.prefillContent ?? '',
    );
    _selectedColor = widget.note?.color;
    _titleDir = detectTextDirection(widget.note?.title);
    _contentDir = detectTextDirection(
      widget.note?.content ?? widget.prefillContent,
    );
    _titleController.addListener(() {
      final dir = detectTextDirection(_titleController.text);
      if (dir != _titleDir) setState(() => _titleDir = dir);
    });
    _contentController.addListener(() {
      final dir = detectTextDirection(_contentController.text);
      if (dir != _contentDir) setState(() => _contentDir = dir);
    });
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

  Color get _bgColor {
    if (_selectedColor != null && _selectedColor!.isNotEmpty) {
      final hex = _selectedColor!.replaceFirst('#', '');
      final value = int.tryParse('FF$hex', radix: 16);
      if (value != null) return Color(value);
    }
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _bgColor;
    final textColor = _contrastColor(bgColor);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        leading: appBarBackLeading(context),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
            child: TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: m.notesWall.title,
                hintStyle: TextStyle(color: textColor.withAlpha(100)),
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              textDirection: _titleDir,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
              child: TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  hintText: m.notesWall.content,
                  hintStyle: TextStyle(color: textColor.withAlpha(100)),
                  border: InputBorder.none,
                ),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: textColor.withAlpha(230),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                textDirection: _contentDir,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 80, 48),
            child: Row(
              children: _colorOptions.map((hex) {
                final color = hex != null
                    ? Color(
                        int.parse('FF${hex.replaceFirst('#', '')}', radix: 16),
                      )
                    : Theme.of(context).colorScheme.surfaceContainerHighest;
                final isSelected = _selectedColor == hex;
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: CustomPaint(
                      foregroundPainter: hex == null
                          ? _DiagonalLinePainter(
                              color: textColor.withAlpha(120),
                            )
                          : null,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: textColor, width: 3)
                              : Border.all(color: textColor.withAlpha(60)),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 18,
                                color: _contrastColor(color),
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static Color _contrastColor(Color bg) {
    return bg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  }
}

class _DiagonalLinePainter extends CustomPainter {
  final Color color;

  _DiagonalLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromCircle(center: center, radius: radius),
        Radius.circular(radius),
      ),
    );
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.85),
      Offset(size.width * 0.85, size.height * 0.15),
      paint,
    );
  }

  @override
  bool shouldRepaint(_DiagonalLinePainter oldDelegate) =>
      color != oldDelegate.color;
}
