import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/utils/entity_icons.dart';
import 'package:pantry_core/utils/text_direction.dart';

import 'tip_stages.dart';
import 'watch_tip_view.dart';

/// One thing worth knowing about the watch: the picture that shows it and the
/// steps the picture walks through.
///
/// [cues] pins each step to the moment in the loop that demonstrates it, which
/// is what lets the prose light up in time with the animation and lets a tapped
/// step seek the picture to itself. One entry per step, ascending, first at 0.
class WatchTip {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final String body;
  final List<String> steps;
  final List<double> cues;

  /// The aside under the steps — the thing that is true but is not a step.
  final String? note;

  final Duration loop;
  final Widget Function(double t) stage;

  const WatchTip({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.steps,
    required this.cues,
    required this.loop,
    required this.stage,
    this.note,
  });

  /// Where the picture rests when the reader has asked for no animation: just
  /// into the last step, which is the outcome the tip is arguing for.
  double get still => (cues.last + 0.05).clamp(0.0, 1.0);

  /// Which step [t] is demonstrating.
  int activeStep(double t) {
    var active = 0;
    for (var i = 0; i < cues.length; i++) {
      if (t >= cues[i]) active = i;
    }
    return active;
  }
}

/// The tips, in the order a wearer meets them: signing in, then the gestures
/// the app is made of, then the things that are true of it.
List<WatchTip> watchTips() {
  final tips = m.watchTips;
  return [
    WatchTip(
      id: 'pair',
      icon: Icons.watch_outlined,
      title: tips.pairTitle,
      subtitle: tips.pairSubtitle,
      body: tips.pairBody,
      steps: [tips.pairStep1, tips.pairStep2, tips.pairStep3, tips.pairStep4],
      cues: const [0, 0.04, 0.46, 0.76],
      note: tips.pairNote,
      loop: const Duration(milliseconds: 9000),
      stage: (t) => PairStage(t: t),
    ),
    WatchTip(
      id: 'items',
      icon: Icons.check_circle_outline,
      title: tips.itemsTitle,
      subtitle: tips.itemsSubtitle,
      body: tips.itemsBody,
      steps: [tips.itemsStep1, tips.itemsStep2, tips.itemsStep3],
      cues: const [0, 0.20, 0.50],
      note: tips.itemsNote,
      loop: const Duration(milliseconds: 9000),
      stage: (t) => ItemsStage(t: t),
    ),
    WatchTip(
      id: 'pages',
      icon: Icons.swipe_outlined,
      title: tips.pagesTitle,
      subtitle: tips.pagesSubtitle,
      body: tips.pagesBody,
      steps: [tips.pagesStep1, tips.pagesStep2, tips.pagesStep3],
      cues: const [0, 0.56, 0.80],
      note: tips.pagesNote,
      loop: const Duration(milliseconds: 10000),
      stage: (t) => PagesStage(t: t),
    ),
    WatchTip(
      id: 'lists',
      icon: EntityIcons.checklists,
      title: tips.listsTitle,
      subtitle: tips.listsSubtitle,
      body: tips.listsBody,
      steps: [tips.listsStep1, tips.listsStep2, tips.listsStep3],
      cues: const [0, 0.18, 0.44],
      note: tips.listsNote,
      loop: const Duration(milliseconds: 9000),
      stage: (t) => ListsStage(t: t),
    ),
    WatchTip(
      id: 'shopping',
      icon: Icons.shopping_cart_checkout,
      title: tips.shoppingTitle,
      subtitle: tips.shoppingSubtitle,
      body: tips.shoppingBody,
      steps: [
        tips.shoppingStep1,
        tips.shoppingStep2,
        tips.shoppingStep3,
        tips.shoppingStep4,
        tips.shoppingStep5,
      ],
      cues: const [0, 0.18, 0.36, 0.58, 0.78],
      note: tips.shoppingNote,
      loop: const Duration(milliseconds: 15000),
      stage: (t) => ShoppingStage(t: t),
    ),
    WatchTip(
      id: 'crown',
      icon: Icons.rotate_right,
      title: tips.crownTitle,
      subtitle: tips.crownSubtitle,
      body: tips.crownBody,
      steps: [tips.crownStep1, tips.crownStep2],
      cues: const [0, 0.54],
      note: tips.crownNote,
      loop: const Duration(milliseconds: 10000),
      stage: (t) => CrownStage(t: t),
    ),
    WatchTip(
      id: 'offline',
      icon: Icons.cloud_off_outlined,
      title: tips.offlineTitle,
      subtitle: tips.offlineSubtitle,
      body: tips.offlineBody,
      steps: [tips.offlineStep1, tips.offlineStep2, tips.offlineStep3],
      cues: const [0, 0.34, 0.72],
      loop: const Duration(milliseconds: 11000),
      stage: (t) => OfflineStage(t: t),
    ),
    WatchTip(
      id: 'tile',
      icon: Icons.dashboard_customize_outlined,
      title: tips.tileTitle,
      subtitle: tips.tileSubtitle,
      body: tips.tileBody,
      steps: [tips.tileStep1, tips.tileStep2, tips.tileStep3],
      cues: const [0, 0.36, 0.64],
      loop: const Duration(milliseconds: 10000),
      stage: (t) => TileStage(t: t),
    ),
  ];
}

/// The tips as rows on the phone's watch page.
///
/// A row per tip rather than one *Help* entry: the titles are the index, and a
/// reader who only wants the shopping one should not have to open a page to
/// find out this app has tips about shopping.
class WatchTipsSection extends StatelessWidget {
  const WatchTipsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 4),
          child: Text(
            m.watchTips.section,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
          child: Text(
            m.watchTips.sectionBody,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final tip in watchTips())
          ListTile(
            leading: Icon(tip.icon),
            title: Text(
              tip.title,
              textDirection: detectTextDirection(tip.title),
            ),
            subtitle: Text(
              tip.subtitle,
              textDirection: detectTextDirection(tip.subtitle),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => WatchTipView(tip: tip))),
          ),
      ],
    );
  }
}
