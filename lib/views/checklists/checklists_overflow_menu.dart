import 'package:flutter/material.dart';

/// One row in the AppBar overflow bottom sheet: a section
/// [ChecklistsOverflowDivider], a plain [ChecklistsOverflowAction], or a toggle
/// [ChecklistsOverflowCheckboxAction].
sealed class ChecklistsOverflowEntry {
  const ChecklistsOverflowEntry();
}

class ChecklistsOverflowDivider extends ChecklistsOverflowEntry {
  const ChecklistsOverflowDivider();
}

class ChecklistsOverflowAction extends ChecklistsOverflowEntry {
  const ChecklistsOverflowAction({
    required this.value,
    required this.icon,
    required this.label,
  });

  /// Dispatched to `_onOverflow` when the row is tapped.
  final String value;
  final IconData icon;
  final String label;
}

class ChecklistsOverflowCheckboxAction extends ChecklistsOverflowEntry {
  const ChecklistsOverflowCheckboxAction({
    required this.value,
    required this.label,
    required this.checked,
  });

  /// Dispatched to `_onOverflow` when the row is tapped.
  final String value;
  final String label;
  final bool checked;
}

/// Radio-style indicator used by the sort options in the AppBar overflow.
/// Hollow circle when unselected; filled accent circle with a white check
/// when selected. Reads as a radio but matches the language of the list-item
/// checkbox.
class ChecklistsRadioIndicator extends StatelessWidget {
  final bool selected;

  const ChecklistsRadioIndicator({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: selected ? cs.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? cs.primary : cs.outlineVariant,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 12, color: Colors.white)
          : null,
    );
  }
}
