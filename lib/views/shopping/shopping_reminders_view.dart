import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/shopping_reminder.dart';
import 'package:pantry_core/services/shopping_service.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';

/// Full-screen manager for a house's shopping reminders. Three fixed-order
/// groups by moment (start / between shops / end); each reminder row can be
/// toggled, edited inline, moved to another moment, deleted, and reordered
/// within its group. An add form sits at the bottom of each group.
class ShoppingRemindersView extends StatefulWidget {
  final int houseId;

  const ShoppingRemindersView({super.key, required this.houseId});

  @override
  State<ShoppingRemindersView> createState() => _ShoppingRemindersViewState();
}

class _ShoppingRemindersViewState extends State<ShoppingRemindersView> {
  ShoppingService get _service => ShoppingService.instance;

  List<ShoppingReminder> _reminders = [];
  bool _loading = true;
  String? _error;

  // One text controller per reminder id, so inline edits keep their cursor.
  final Map<int, TextEditingController> _textControllers = {};

  @override
  void initState() {
    super.initState();
    final cached = _service.getCachedReminders(widget.houseId);
    if (cached != null) {
      _reminders = cached;
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final reminders = await _service.getReminders(widget.houseId);
      if (!mounted) return;
      setState(() {
        _reminders = reminders;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_reminders.isEmpty) _error = m.shopping.loadFailed;
      });
    }
  }

  List<ShoppingReminder> _group(ShoppingReminderMoment moment) =>
      (_reminders.where((r) => r.showOn == moment).toList()
        ..sort((a, b) => a.position.compareTo(b.position)));

  TextEditingController _controllerFor(ShoppingReminder r) {
    final existing = _textControllers[r.id];
    if (existing != null) {
      if (existing.text != r.text &&
          !existing.selection.isValid &&
          FocusManager.instance.primaryFocus?.hasFocus != true) {
        existing.text = r.text;
      }
      return existing;
    }
    return _textControllers[r.id] = TextEditingController(text: r.text);
  }

  void _replace(ShoppingReminder updated) {
    setState(() {
      _reminders = [
        for (final r in _reminders) r.id == updated.id ? updated : r,
      ];
    });
  }

  Future<void> _persistUpdate(
    ShoppingReminder r, {
    String? text,
    ShoppingReminderMoment? showOn,
    bool? enabled,
  }) async {
    // Optimistic; revert to a reload on failure.
    _replace(r.copyWith(text: text, showOn: showOn, enabled: enabled));
    try {
      final updated = await _service.updateReminder(
        widget.houseId,
        r.id,
        text: text,
        showOn: showOn,
        enabled: enabled,
      );
      _replace(updated);
    } catch (_) {
      _showError(m.shopping.reminderSaveFailed);
      await _load();
    }
  }

  Future<void> _delete(ShoppingReminder r) async {
    setState(() => _reminders = _reminders.where((x) => x.id != r.id).toList());
    _textControllers.remove(r.id)?.dispose();
    try {
      await _service.deleteReminder(widget.houseId, r.id);
    } catch (_) {
      _showError(m.shopping.reminderDeleteFailed);
      await _load();
    }
  }

  Future<void> _add(String text, ShoppingReminderMoment moment) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      final created = await _service.createReminder(
        widget.houseId,
        text: trimmed,
        showOn: moment,
      );
      if (!mounted) return;
      setState(() => _reminders = [..._reminders, created]);
    } catch (_) {
      _showError(m.shopping.reminderSaveFailed);
    }
  }

  Future<void> _reorderWithin(
    ShoppingReminderMoment moment,
    int oldIndex,
    int newIndex,
  ) async {
    final group = _group(moment);
    if (oldIndex == newIndex) return;
    final moved = group.removeAt(oldIndex);
    group.insert(newIndex, moved);

    // Rebuild the full ordered id list across all groups (fixed group order)
    // so positions come out consistent, then persist in one call.
    final ordered = <ShoppingReminder>[];
    for (final mm in ShoppingReminderMoment.values) {
      ordered.addAll(mm == moment ? group : _group(mm));
    }
    setState(() {
      _reminders = [
        for (var i = 0; i < ordered.length; i++)
          ordered[i].copyWith(position: i),
      ];
    });
    try {
      final result = await _service.reorderReminders(
        widget.houseId,
        ordered.map((r) => r.id).toList(),
      );
      if (!mounted) return;
      setState(() => _reminders = result);
    } catch (_) {
      _showError(m.shopping.reminderSaveFailed);
      await _load();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _momentLabel(ShoppingReminderMoment moment) => switch (moment) {
    ShoppingReminderMoment.onStart => m.shopping.reminderGroupStart,
    ShoppingReminderMoment.onStoreAdvance => m.shopping.reminderGroupAdvance,
    ShoppingReminderMoment.onClose => m.shopping.reminderGroupEnd,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: appBarBackLeading(context),
        title: Text(m.shopping.remindersTitle),
      ),
      body: _loading && _reminders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _reminders.isEmpty
          ? _ErrorRetry(message: _error!, onRetry: _load)
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final moment in ShoppingReminderMoment.values)
                  _MomentGroup(
                    label: _momentLabel(moment),
                    reminders: _group(moment),
                    controllerFor: _controllerFor,
                    momentLabelFor: _momentLabel,
                    onReorder: (o, n) => _reorderWithin(moment, o, n),
                    onToggle: (r, v) => _persistUpdate(r, enabled: v),
                    onEditText: (r, t) {
                      if (t.trim().isNotEmpty && t.trim() != r.text) {
                        _persistUpdate(r, text: t.trim());
                      }
                    },
                    onChangeMoment: (r, mm) => _persistUpdate(r, showOn: mm),
                    onDelete: _delete,
                    onAdd: (t) => _add(t, moment),
                  ),
              ],
            ),
    );
  }
}

class _MomentGroup extends StatefulWidget {
  final String label;
  final List<ShoppingReminder> reminders;
  final TextEditingController Function(ShoppingReminder) controllerFor;
  final String Function(ShoppingReminderMoment) momentLabelFor;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(ShoppingReminder, bool) onToggle;
  final void Function(ShoppingReminder, String) onEditText;
  final void Function(ShoppingReminder, ShoppingReminderMoment) onChangeMoment;
  final void Function(ShoppingReminder) onDelete;
  final void Function(String) onAdd;

  const _MomentGroup({
    required this.label,
    required this.reminders,
    required this.controllerFor,
    required this.momentLabelFor,
    required this.onReorder,
    required this.onToggle,
    required this.onEditText,
    required this.onChangeMoment,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  State<_MomentGroup> createState() => _MomentGroupState();
}

class _MomentGroupState extends State<_MomentGroup> {
  final _addCtrl = TextEditingController();

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  void _submitAdd() {
    final text = _addCtrl.text;
    if (text.trim().isEmpty) return;
    widget.onAdd(text);
    _addCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: 16,
            end: 16,
            top: 16,
            bottom: 4,
          ),
          child: Text(
            widget.label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        if (widget.reminders.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 16,
              end: 16,
              bottom: 4,
            ),
            child: Text(
              m.shopping.noRemindersHere,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: widget.reminders.length,
            onReorderItem: widget.onReorder,
            itemBuilder: (context, index) {
              final r = widget.reminders[index];
              return _ReminderEditRow(
                key: ValueKey(r.id),
                index: index,
                reminder: r,
                controller: widget.controllerFor(r),
                momentLabelFor: widget.momentLabelFor,
                onToggle: (v) => widget.onToggle(r, v),
                onEditText: (t) => widget.onEditText(r, t),
                onChangeMoment: (mm) => widget.onChangeMoment(r, mm),
                onDelete: () => widget.onDelete(r),
              );
            },
          ),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: 16,
            end: 8,
            top: 4,
            bottom: 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addCtrl,
                  textDirection: detectTextDirection(_addCtrl.text),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: m.shopping.addReminderHint,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submitAdd(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _submitAdd,
                child: Text(m.shopping.add),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _ReminderEditRow extends StatelessWidget {
  final int index;
  final ShoppingReminder reminder;
  final TextEditingController controller;
  final String Function(ShoppingReminderMoment) momentLabelFor;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onEditText;
  final ValueChanged<ShoppingReminderMoment> onChangeMoment;
  final VoidCallback onDelete;

  const _ReminderEditRow({
    super.key,
    required this.index,
    required this.reminder,
    required this.controller,
    required this.momentLabelFor,
    required this.onToggle,
    required this.onEditText,
    required this.onChangeMoment,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, end: 8, top: 2),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.drag_handle, size: 20),
            ),
          ),
          Switch(value: reminder.enabled, onChanged: onToggle),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller,
              textDirection: detectTextDirection(controller.text),
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
              ),
              onTapOutside: (_) => onEditText(controller.text),
              onEditingComplete: () => onEditText(controller.text),
            ),
          ),
          PopupMenuButton<ShoppingReminderMoment>(
            icon: const Icon(Icons.schedule, size: 20),
            tooltip: m.shopping.reminderWhen,
            initialValue: reminder.showOn,
            onSelected: onChangeMoment,
            itemBuilder: (context) => [
              for (final mm in ShoppingReminderMoment.values)
                PopupMenuItem(value: mm, child: Text(momentLabelFor(mm))),
            ],
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(m.common.retry)),
          ],
        ),
      ),
    );
  }
}
