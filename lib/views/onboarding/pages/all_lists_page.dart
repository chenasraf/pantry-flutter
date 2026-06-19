import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/utils/checklist_icons.dart';

/// Introduces the All-lists meta view added in 0.17.0. Shows a mocked
/// AppBar with the dashboard icon, a couple of item rows tagged with their
/// owning-list badges, and the compose bar with the new "List" chip
/// highlighted — the one the user has to pick from when adding an item
/// from this view.
class AllListsOnboardingPage extends StatelessWidget {
  const AllListsOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ob = m.onboarding;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ob.allListsTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.allListsBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const _MockAllListsTitleBar(),
          const SizedBox(height: 10),
          _MockItemRow(
            name: ob.mockItemName,
            badgeLabel: ob.mockListGroceries,
            badgeIcon: 'cart',
          ),
          const SizedBox(height: 8),
          _MockItemRow(
            name: ob.mockHardwareItemName,
            badgeLabel: ob.mockListHardware,
            badgeIcon: 'wrench',
          ),
          const SizedBox(height: 16),
          const _MockComposeWithListChip(),
        ],
      ),
    );
  }
}

/// AppBar mock — All-lists dashboard icon tile + "All lists" label.
class _MockAllListsTitleBar extends StatelessWidget {
  const _MockAllListsTitleBar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(allListsIcon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              m.checklists.allLists,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: cs.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: cs.onSurfaceVariant, size: 22),
        ],
      ),
    );
  }
}

/// Mock list-item row carrying a small list-name badge on the trailing edge —
/// the visual cue that the item lives on a different underlying list.
class _MockItemRow extends StatelessWidget {
  final String name;
  final String badgeLabel;
  final String badgeIcon;

  const _MockItemRow({
    required this.name,
    required this.badgeLabel,
    required this.badgeIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cs.outline, width: 1.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _ListBadge(label: badgeLabel, iconKey: badgeIcon),
        ],
      ),
    );
  }
}

class _ListBadge extends StatelessWidget {
  final String label;
  final String iconKey;

  const _ListBadge({required this.label, required this.iconKey});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(7, 4, 9, 4),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(checklistIcon(iconKey), size: 12, color: cs.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact compose-bar mock that highlights the new "List" chip — the
/// destination picker that appears when adding from the All-lists view.
class _MockComposeWithListChip extends StatelessWidget {
  const _MockComposeWithListChip();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 36,
            child: Row(
              children: [
                _HighlightedListChip(
                  label: m.checklists.compose.chipTargetList,
                  value: m.checklists.compose.pickTargetList,
                ),
                const SizedBox(width: 8),
                _DimChip(
                  label: m.checklists.compose.chipCategory,
                  icon: Icons.label_outline,
                ),
                const SizedBox(width: 8),
                _DimChip(
                  label: m.checklists.compose.chipQuantity,
                  icon: Icons.format_list_numbered,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _MockInputBar(placeholder: m.checklists.addToAnyList),
        ],
      ),
    );
  }
}

class _HighlightedListChip extends StatelessWidget {
  final String label;
  final String value;

  const _HighlightedListChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 7, 12, 7),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.16),
        border: Border.all(color: cs.primary, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist_rtl, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DimChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _DimChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockInputBar extends StatelessWidget {
  final String placeholder;

  const _MockInputBar({required this.placeholder});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 6, 6),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.add, color: cs.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              placeholder,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
