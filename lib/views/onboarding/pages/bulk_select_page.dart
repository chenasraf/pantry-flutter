import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';

/// Teaches multi-select (group actions). Runs a continuous demo that selects a
/// few mocked rows one after another, brings up the group-action bar, holds so
/// the reader can take it in, then resets — mirroring the real "long-press /
/// Select items → pick an action" flow without the reader touching anything.
class BulkSelectOnboardingPage extends StatefulWidget {
  const BulkSelectOnboardingPage({super.key});

  @override
  State<BulkSelectOnboardingPage> createState() =>
      _BulkSelectOnboardingPageState();
}

class _BulkSelectOnboardingPageState extends State<BulkSelectOnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Fractions of one loop at which each row flips to selected. Staggered so
  // the eye follows the selection building up row by row.
  static const List<double> _rowSelectAt = [0.08, 0.21, 0.34];
  // Everything stays selected until here, then the demo resets to idle.
  static const double _resetAt = 0.86;

  bool _rowSelected(int i, double t) => t >= _rowSelectAt[i] && t < _resetAt;

  /// 0..1 presence of the action bar: ramps in as the first row is selected,
  /// holds while the selection stands, ramps back out on reset.
  double _barPresence(double t) {
    const inStart = 0.08;
    const inEnd = 0.18;
    const outEnd = 0.96;
    if (t < inStart) return 0;
    if (t < inEnd) return (t - inStart) / (inEnd - inStart);
    if (t < _resetAt) return 1;
    if (t < outEnd) return 1 - (t - _resetAt) / (outEnd - _resetAt);
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ob = m.onboarding;
    // Reuse the real feature's action + count labels so the demo reads exactly
    // like the live UI.
    final rows = [ob.mockItemName, ob.mockBulkItemThird, ob.mockBulkItemFourth];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ob.bulkSelectTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.bulkSelectBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final selected = [
                for (var i = 0; i < rows.length; i++) _rowSelected(i, t),
              ];
              final count = selected.where((s) => s).length;
              final presence = _barPresence(t);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Count pill — mirrors the "N selected" the AppBar shows in
                  // selection mode. Kept in the layout (via Opacity) so the
                  // card below doesn't jump as it appears.
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Opacity(
                      opacity: presence,
                      child: _CountPill(
                        label: m.checklists.batch.selected(
                          count == 0 ? 1 : count,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    foregroundDecoration: BoxDecoration(
                      border: Border.all(color: cs.outlineVariant),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < rows.length; i++)
                          _MockSelectRow(
                            name: rows[i],
                            selected: selected[i],
                            showDivider: i > 0,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Slide the action bar up a touch as it fades in.
                  Transform.translate(
                    offset: Offset(0, (1 - presence) * 10),
                    child: Opacity(
                      opacity: presence,
                      child: const _MockActionBar(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The rounded "N selected" pill shown while items are selected.
class _CountPill extends StatelessWidget {
  final String label;

  const _CountPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cs.primary,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A mocked selectable row: leading selection circle + item name, with the
/// primary tint wash the real tile shows while selected.
class _MockSelectRow extends StatelessWidget {
  final String name;
  final bool selected;
  final bool showDivider;

  const _MockSelectRow({
    required this.name,
    required this.selected,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: selected
            ? Color.alphaBlend(cs.primary.withValues(alpha: 0.12), cs.surface)
            : cs.surface,
        border: showDivider
            ? Border(top: BorderSide(color: cs.outlineVariant))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 24,
            color: selected ? cs.primary : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A mock of the bottom group-action bar — Move / Copy / Category / Delete,
/// reusing the live labels and icons.
class _MockActionBar extends StatelessWidget {
  const _MockActionBar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final b = m.checklists.batch;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
      child: Row(
        children: [
          _MockAction(icon: Icons.drive_file_move_outlined, label: b.move),
          _MockAction(icon: Icons.copy_outlined, label: b.copy),
          _MockAction(icon: Icons.sell_outlined, label: b.category),
          _MockAction(icon: Icons.delete_outline, label: b.delete),
        ],
      ),
    );
  }
}

class _MockAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MockAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: cs.onSurface),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: cs.onSurface),
          ),
        ],
      ),
    );
  }
}
