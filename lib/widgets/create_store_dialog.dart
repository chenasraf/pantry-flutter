import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/store.dart';
import 'package:pantry/utils/opening_hours.dart';
import 'package:pantry/utils/store_icons.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/sync/sync_ids.dart';
import 'package:pantry/sync/sync_manager.dart';
import 'package:pantry/sync/sync_op.dart';

const storeColors = [
  '#e11d48',
  '#ea580c',
  '#ca8a04',
  '#16a34a',
  '#0891b2',
  '#2563eb',
  '#7c3aed',
  '#c026d3',
  '#db2777',
  '#57534e',
];

class CreateStoreDialog extends StatefulWidget {
  final int houseId;

  /// If non-null, we're editing this store instead of creating a new one.
  final Store? existing;

  const CreateStoreDialog({super.key, required this.houseId, this.existing});

  @override
  State<CreateStoreDialog> createState() => _CreateStoreDialogState();
}

class _CreateStoreDialogState extends State<CreateStoreDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _contactController;
  late final TextEditingController _responsibleController;
  late final TextEditingController _notesController;
  late String _selectedIcon;
  late String _selectedColor;

  /// Working copy of the store's opening hours.
  late List<OpeningHoursInterval> _hours;

  // Add-interval row state.
  bool _showAddRow = false;
  final Set<int> _selectedDays = {};
  TimeOfDay? _addStart;
  TimeOfDay? _addEnd;

  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _locationController = TextEditingController(text: e?.location ?? '');
    _contactController = TextEditingController(text: e?.contact ?? '');
    _responsibleController = TextEditingController(text: e?.responsible ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');
    _selectedIcon = e?.icon ?? 'store';
    _selectedColor = e?.color ?? storeColors.first;
    _hours = [...?e?.openingHours];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _responsibleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

  bool get _canAddInterval =>
      _selectedDays.isNotEmpty &&
      _addStart != null &&
      _addEnd != null &&
      _minutes(_addStart!) < _minutes(_addEnd!);

  void _addIntervals() {
    if (!_canAddInterval) return;
    final start = _fmtTime(_addStart!);
    final end = _fmtTime(_addEnd!);
    setState(() {
      for (final day in _selectedDays) {
        _hours.add(OpeningHoursInterval(day: day, start: start, end: end));
      }
      _selectedDays.clear();
      _addStart = null;
      _addEnd = null;
    });
  }

  void _removeInterval(OpeningHoursInterval interval) {
    setState(() => _hours.remove(interval));
  }

  Future<void> _pickTime(bool isStart) async {
    // Drop focus from any text field first: otherwise the picker route restores
    // focus to it on close, re-opening the keyboard and shifting the layout.
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showTimePicker(
      context: context,
      initialTime:
          (isStart ? _addStart : _addEnd) ??
          const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _addStart = picked;
      } else {
        _addEnd = picked;
      }
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // Sort by [day, start] to mirror the server's canonical ordering.
    final hours = [..._hours]
      ..sort((a, b) {
        final byDay = a.day.compareTo(b.day);
        return byDay != 0 ? byDay : a.start.compareTo(b.start);
      });

    final location = _locationController.text.trim();
    final contact = _contactController.text.trim();
    final responsible = _responsibleController.text.trim();
    final notes = _notesController.text.trim();

    // Always send every field so a cleared value reaches the server as an
    // empty string / empty list, which it maps to null.
    final body = <String, dynamic>{
      'name': name,
      'icon': _selectedIcon,
      'color': _selectedColor,
      'location': location,
      'openingHours': hours.map((e) => e.toJson()).toList(),
      'contact': contact,
      'responsible': responsible,
      'notes': notes,
    };

    setState(() => _saving = true);
    final sync = SyncManager.instance;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Empty text/list become null on the local optimistic copy so the details
    // view treats them as absent.
    String? orNull(String v) => v.isEmpty ? null : v;
    final localHours = hours.isEmpty ? null : hours;

    final Store result;
    if (_isEditing) {
      final existing = widget.existing!;
      result = Store(
        id: existing.id,
        houseId: existing.houseId,
        name: name,
        icon: _selectedIcon,
        color: _selectedColor,
        location: orNull(location),
        openingHours: localHours,
        contact: orNull(contact),
        responsible: orNull(responsible),
        notes: orNull(notes),
        createdAt: existing.createdAt,
        updatedAt: now,
      );
      sync.enqueue(
        SyncOp(
          uuid: SyncIds.newOpUuid(),
          entity: SyncEntity.store,
          op: SyncOpKind.update,
          houseId: widget.houseId,
          entityId: existing.id < 0 ? null : existing.id,
          tempEntityId: existing.id < 0 ? existing.id : null,
          body: body,
          createdAt: now,
        ),
      );
    } else {
      final tempId = sync.newTempId();
      result = Store(
        id: tempId,
        houseId: widget.houseId,
        name: name,
        icon: _selectedIcon,
        color: _selectedColor,
        location: orNull(location),
        openingHours: localHours,
        contact: orNull(contact),
        responsible: orNull(responsible),
        notes: orNull(notes),
        createdAt: now,
        updatedAt: now,
      );
      sync.enqueue(
        SyncOp(
          uuid: SyncIds.newOpUuid(),
          entity: SyncEntity.store,
          op: SyncOpKind.create,
          houseId: widget.houseId,
          tempEntityId: tempId,
          body: body,
          createdAt: now,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop(result);
  }

  Color _parseHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_isEditing ? m.stores.editTitle : m.stores.addTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: m.stores.name,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(m.stores.icon, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: storeIconMap.entries.map((entry) {
                final isSelected = _selectedIcon == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = entry.key),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Icon(
                      entry.value,
                      size: 20,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(m.stores.color, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: storeColors.map((hex) {
                final color = _parseHex(hex);
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
                              color: theme.colorScheme.primary,
                              width: 3,
                            )
                          : Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _infoField(
              controller: _locationController,
              label: m.stores.location,
              hint: m.stores.locationHint,
            ),
            const SizedBox(height: 16),
            Text(m.stores.openingHours, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            _buildHoursEditor(theme),
            const SizedBox(height: 16),
            _infoField(
              controller: _contactController,
              label: m.stores.contact,
              hint: m.stores.contactHint,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _infoField(
              controller: _responsibleController,
              label: m.stores.responsible,
              hint: m.stores.responsibleHint,
            ),
            const SizedBox(height: 16),
            _infoField(
              controller: _notesController,
              label: m.stores.notes,
              hint: m.stores.notesHint,
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(m.common.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(m.common.save),
        ),
      ],
    );
  }

  Widget _infoField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        textDirection: detectTextDirection(value.text),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildHoursEditor(ThemeData theme) {
    final grouped = OpeningHoursDisplay.groupByDay(context, _hours);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (grouped.isNotEmpty) ...[
          for (final entry in grouped)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(top: 6),
                      child: Text(
                        OpeningHoursDisplay.weekdayName(context, entry.key),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final interval in entry.value)
                          InputChip(
                            label: Text(
                              '${OpeningHoursDisplay.formatTime(context, interval.start)}–'
                              '${OpeningHoursDisplay.formatTime(context, interval.end)}',
                            ),
                            onDeleted: () => _removeInterval(interval),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
        if (_showAddRow)
          _buildAddRow(theme)
        else
          OutlinedButton.icon(
            onPressed: () => setState(() => _showAddRow = true),
            icon: const Icon(Icons.add, size: 18),
            label: Text(m.stores.addOpeningHours),
          ),
      ],
    );
  }

  Widget _buildAddRow(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final day in OpeningHoursDisplay.weekdayOrder(context))
                FilterChip(
                  label: Text(
                    OpeningHoursDisplay.weekdayName(context, day, short: true),
                  ),
                  selected: _selectedDays.contains(day),
                  onSelected: (sel) => setState(() {
                    if (sel) {
                      _selectedDays.add(day);
                    } else {
                      _selectedDays.remove(day);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickTime(true),
                  child: Text(
                    _addStart != null
                        ? MaterialLocalizations.of(
                            context,
                          ).formatTimeOfDay(_addStart!)
                        : m.stores.openingHoursStart,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickTime(false),
                  child: Text(
                    _addEnd != null
                        ? MaterialLocalizations.of(
                            context,
                          ).formatTimeOfDay(_addEnd!)
                        : m.stores.openingHoursEnd,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _showAddRow = false;
                  _selectedDays.clear();
                  _addStart = null;
                  _addEnd = null;
                }),
                child: Text(m.common.cancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _canAddInterval ? _addIntervals : null,
                child: Text(m.stores.openingHoursAdd),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
