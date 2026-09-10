import 'dart:async';

import 'package:flutter/material.dart';

import 'focus_list.dart';
import 'wear_ink.dart';
import 'wear_mechanics.dart';
import 'wear_metrics.dart';
import 'wear_row.dart';

/// One option on a [WearChoicePage].
@immutable
class WearChoice<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color tint;

  const WearChoice({
    required this.value,
    required this.label,
    this.icon,
    this.tint = Colors.white70,
  });
}

/// A pushed page that asks the wearer to pick one of a short list.
///
/// The house, the list and the refresh interval are the same question with
/// different nouns, so they are the same page — one row geometry and one back
/// gesture, rather than three that drift apart.
///
/// It is built on [SnapFocusList] for the shape rather than for the focus: a
/// round screen is only as wide as its chord, so a row held at full width has
/// its ends shaved everywhere but the middle of the glass, and the falloff is
/// what buys that width back — rows narrow as they leave the centre line, which
/// is how fast the bezel closes in on them.
///
/// Rows are still tapped where they lie rather than dragged to the centre line.
/// The "middle one is in charge" rule earns its cost where a tap writes
/// something; a setting is visible in the row it was set from and one tap to
/// put back.
///
/// The page opens on the answer it already holds, so confirming one is a glance
/// and changing it is a turn of the crown.
class WearChoicePage<T> extends StatefulWidget {
  final List<WearChoice<T>> choices;
  final T? selected;

  /// Said in place of the list when there is nothing to choose between.
  final String empty;

  /// Awaited before the page pops, so the choice is written before the surface
  /// that reads it is uncovered.
  final Future<void> Function(T value) onSelected;

  const WearChoicePage({
    super.key,
    required this.choices,
    required this.selected,
    required this.empty,
    required this.onSelected,
  });

  @override
  State<WearChoicePage<T>> createState() => _WearChoicePageState<T>();
}

class _WearChoicePageState<T> extends State<WearChoicePage<T>> {
  final _scroll = ScrollController();
  final _listKey = GlobalKey<SnapFocusListState>();

  /// A second tap while the first is still being written would pop a page that
  /// is already leaving.
  var _choosing = false;

  @override
  void initState() {
    super.initState();
    _landOnSelection(_listKey, widget.choices.indexWhere(_isSelected));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _isSelected(WearChoice<T> choice) => choice.value == widget.selected;

  Future<void> _select(T value) async {
    if (_choosing) return;
    _choosing = true;
    await widget.onSelected(value);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => _ChoiceList(
    listKey: _listKey,
    scroll: _scroll,
    choices: widget.choices,
    empty: widget.empty,
    isSelected: _isSelected,
    onTap: (choice) => unawaited(_select(choice.value)),
  );
}

/// The same page, asking for any number of the list rather than one of it.
///
/// It does not pop on a tap and it returns nothing: a set is not finished until
/// the wearer says so, and the back gesture every pushed route already carries
/// is what says it. The caller sees each change as it happens, so what it holds
/// is always what the page is showing.
class WearMultiChoicePage<T> extends StatefulWidget {
  final List<WearChoice<T>> choices;
  final Set<T> selected;

  /// Said in place of the list when there is nothing to choose between.
  final String empty;

  final void Function(Set<T> selected) onChanged;

  const WearMultiChoicePage({
    super.key,
    required this.choices,
    required this.selected,
    required this.empty,
    required this.onChanged,
  });

  @override
  State<WearMultiChoicePage<T>> createState() => _WearMultiChoicePageState<T>();
}

class _WearMultiChoicePageState<T> extends State<WearMultiChoicePage<T>> {
  final _scroll = ScrollController();
  final _listKey = GlobalKey<SnapFocusListState>();
  late final Set<T> _selected = {...widget.selected};

  @override
  void initState() {
    super.initState();
    // The first one already on, so a set the wearer is amending opens at the
    // part of it they can amend.
    _landOnSelection(
      _listKey,
      widget.choices.indexWhere((c) => _selected.contains(c.value)),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _toggle(T value) {
    setState(() {
      if (!_selected.remove(value)) _selected.add(value);
    });
    widget.onChanged({..._selected});
  }

  @override
  Widget build(BuildContext context) => _ChoiceList(
    listKey: _listKey,
    scroll: _scroll,
    choices: widget.choices,
    empty: widget.empty,
    checkbox: true,
    isSelected: (choice) => _selected.contains(choice.value),
    onTap: (choice) => _toggle(choice.value),
  );
}

/// Carry the list to the row that is already the answer, once the list has
/// been laid out and knows where its rows are.
///
/// A no-op where nothing is selected, and where the list has no centre line to
/// land on — a flat list starts at the top and every row is as reachable as
/// every other.
void _landOnSelection(GlobalKey<SnapFocusListState> key, int index) {
  if (index < 0 || !SnapFocusList.hasFocusRow) return;
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => key.currentState?.centreOn(index),
  );
}

/// What both pages draw.
class _ChoiceList<T> extends StatelessWidget {
  final GlobalKey<SnapFocusListState> listKey;
  final ScrollController scroll;
  final List<WearChoice<T>> choices;
  final String empty;
  final bool checkbox;
  final bool Function(WearChoice<T> choice) isSelected;
  final void Function(WearChoice<T> choice) onTap;

  const _ChoiceList({
    required this.listKey,
    required this.scroll,
    required this.choices,
    required this.empty,
    required this.isSelected,
    required this.onTap,
    this.checkbox = false,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = WearMetrics.of(context);
    return Scaffold(
      backgroundColor: wearGround,
      body: EdgeDismissible(
        onDismiss: () => Navigator.of(context).pop(),
        child: choices.isEmpty
            ? _Empty(message: empty)
            : SnapFocusList(
                key: listKey,
                controller: scroll,
                itemExtent: metrics.itemExtent,
                falloffRows: WearMetrics.falloffRows,
                rotaryActive: true,
                horizontalInset: WearMetrics.sideInset,
                elements: [
                  for (var i = 0; i < choices.length; i++)
                    FocusElement(
                      extent: metrics.itemExtent,
                      builder: (context, d) => Padding(
                        padding: EdgeInsetsDirectional.only(
                          bottom: metrics.cardGap,
                        ),
                        child: WearRow(
                          icon: choices[i].icon,
                          tint: choices[i].tint,
                          label: choices[i].label,
                          checkbox: checkbox,
                          selected: isSelected(choices[i]),
                          distance: d,
                          onTap: () => onTap(choices[i]),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Nothing to choose between, said where the rows would have been.
class _Empty extends StatelessWidget {
  final String message;

  const _Empty({required this.message});

  @override
  Widget build(BuildContext context) => Padding(
    padding: WearMetrics.bandInsets(context),
    child: Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: Colors.white38),
      ),
    ),
  );
}
