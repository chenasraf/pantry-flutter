import 'package:flutter/material.dart';

import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/list_kind.dart';
import 'package:pantry_core/utils/color.dart';

import 'home_floating_nav.dart' show NavDestination;

/// The checklists the checklists section hands the side rail, so the rail can
/// draw one entry per list beneath its own destination and switch between them.
class HomeNavListsSpec {
  /// Every list, grouped by kind in navigation order.
  final List<ChecklistList> lists;
  final int? currentListId;
  final void Function(ChecklistList list) onSelect;

  /// Opens a kind's section. Set when the server has list kinds, which the
  /// rail then heads with their names.
  final void Function(ListKind kind)? onSelectKind;

  const HomeNavListsSpec({
    required this.lists,
    required this.currentListId,
    required this.onSelect,
    this.onSelectKind,
  });

  // The section re-offers this on every build, each offer carrying a freshly
  // built closure. Comparing those would make every offer a change, and the
  // change rebuilds home — so equality is over what the rail draws.
  @override
  bool operator ==(Object other) =>
      other is HomeNavListsSpec &&
      other.currentListId == currentListId &&
      (other.onSelectKind == null) == (onSelectKind == null) &&
      other.lists.length == lists.length &&
      Iterable<int>.generate(lists.length).every(
        (i) =>
            other.lists[i].id == lists[i].id &&
            other.lists[i].name == lists[i].name &&
            other.lists[i].icon == lists[i].icon &&
            other.lists[i].color == lists[i].color &&
            other.lists[i].needsRestock == lists[i].needsRestock,
      );

  @override
  int get hashCode => Object.hash(
    currentListId,
    Object.hashAll([
      for (final l in lists)
        Object.hash(l.id, l.name, l.icon, l.color, l.needsRestock),
    ]),
  );
}

/// One entry nested under a rail destination. [color] tints the icon's
/// container; a null one falls back to the theme's primary.
class NavRailNested {
  final IconData icon;
  final Color? color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Heads a group of entries rather than standing for one.
  final bool header;

  /// A count drawn beside the entry, with [counterLabel] spelling it out.
  /// Nothing is drawn at 0.
  final int counter;
  final String? counterLabel;

  const NavRailNested({
    required this.icon,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
    this.counter = 0,
    this.counterLabel,
  }) : header = false;

  const NavRailNested.header({
    required this.icon,
    required this.label,
    required this.onTap,
  }) : color = null,
       selected = false,
       header = true,
       counter = 0,
       counterLabel = null;
}

/// Vertical navigation rail for the wide layout: the sections, with [nested]
/// entries drawn under the destination at [nestedIndex].
///
/// [extended] lays destinations out as rows with their label beside the icon;
/// otherwise the rail is a narrow column of icons over their labels.
class HomeNavRail extends StatelessWidget {
  final bool extended;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavDestination> destinations;
  final int? nestedIndex;
  final List<NavRailNested> nested;
  final Widget? leading;

  const HomeNavRail({
    super.key,
    required this.extended,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.nestedIndex,
    this.nested = const [],
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      child: SizedBox(
        width: extended ? 256 : 80,
        // The rail is a Row child, which would otherwise leave it hugging its
        // entries and floating in the middle of the window.
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?leading,
              const SizedBox(height: 8),
              for (var i = 0; i < destinations.length; i++) ...[
                _RailDestination(
                  destination: destinations[i],
                  selected: i == selectedIndex,
                  extended: extended,
                  onTap: () => onDestinationSelected(i),
                ),
                if (i == nestedIndex)
                  for (final entry in nested)
                    _RailNestedEntry(entry: entry, extended: extended),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailDestination extends StatelessWidget {
  final NavDestination destination;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  const _RailDestination({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final foreground = selected ? cs.onSecondaryContainer : cs.onSurfaceVariant;
    final indicator = selected ? cs.secondaryContainer : Colors.transparent;

    if (extended) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            height: 56,
            decoration: BoxDecoration(
              color: indicator,
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsetsDirectional.only(start: 16, end: 20),
            child: Row(
              children: [
                Icon(destination.icon, size: 24, color: foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 32,
              decoration: BoxDecoration(
                color: indicator,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(destination.icon, size: 24, color: foreground),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? cs.onSurface : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailNestedEntry extends StatelessWidget {
  final NavRailNested entry;
  final bool extended;

  const _RailNestedEntry({required this.entry, required this.extended});

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!extended) {
      return Tooltip(
        message: entry.label,
        child: InkWell(
          onTap: entry.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: Divider(height: 1, color: cs.outlineVariant),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 28,
        end: 12,
        top: 8,
        bottom: 2,
      ),
      child: InkWell(
        onTap: entry.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          child: Row(
            children: [
              Icon(entry.icon, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (entry.header) return _buildHeader(context);
    final cs = Theme.of(context).colorScheme;
    final tint = entry.color ?? cs.primary;
    final badge = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(entry.icon, size: 16, color: noteInk(tint)),
    );
    final counter = entry.counter > 0
        ? Tooltip(
            message: entry.counterLabel ?? '',
            child: Semantics(
              label: entry.counterLabel,
              excludeSemantics: true,
              child: Badge(
                label: Text('${entry.counter}'),
                backgroundColor: cs.error,
                textColor: cs.onError,
              ),
            ),
          )
        : null;
    final indicator = entry.selected
        ? cs.secondaryContainer
        : Colors.transparent;

    if (extended) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(
          start: 28,
          end: 12,
          top: 1,
          bottom: 1,
        ),
        child: InkWell(
          onTap: entry.onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            height: 44,
            decoration: BoxDecoration(
              color: indicator,
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsetsDirectional.only(start: 8, end: 14),
            child: Row(
              children: [
                badge,
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: entry.selected
                          ? cs.onSurface
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                if (counter != null) ...[const SizedBox(width: 8), counter],
              ],
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: entry.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
        child: InkWell(
          onTap: entry.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            height: 40,
            decoration: BoxDecoration(
              color: indicator,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: counter == null
                  ? badge
                  : Badge(
                      label: Text('${entry.counter}'),
                      backgroundColor: cs.error,
                      textColor: cs.onError,
                      child: badge,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
