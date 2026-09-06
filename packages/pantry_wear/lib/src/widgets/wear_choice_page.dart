import 'dart:async';

import 'package:flutter/material.dart';

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
/// The household, the list and the refresh interval are the same question with
/// different nouns, so they are the same page — one row geometry and one back
/// gesture, rather than three that drift apart.
///
/// Rows are tapped where they lie, not dragged to a centre line: the falloff's
/// "the middle one is in charge" rule earns its cost on a page whose rail
/// reads the focus, and there is no rail here. Every row is its own target.
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

  /// A second tap while the first is still being written would pop a page that
  /// is already leaving.
  var _choosing = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _select(T value) async {
    if (_choosing) return;
    _choosing = true;
    await widget.onSelected(value);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      body: EdgeDismissible(
        onDismiss: () => Navigator.of(context).pop(),
        child: RotaryScrollable(
          controller: _scroll,
          active: true,
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 10,
              vertical: 44,
            ),
            children: [
              if (widget.choices.isEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 12),
                  child: Text(
                    widget.empty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ),
              for (final choice in widget.choices)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: WearMetrics.cardGap,
                  ),
                  child: SizedBox(
                    height: WearMetrics.cardHeight,
                    child: WearRow(
                      icon: choice.icon,
                      tint: choice.tint,
                      label: choice.label,
                      selected: choice.value == widget.selected,
                      onTap: () => unawaited(_select(choice.value)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
