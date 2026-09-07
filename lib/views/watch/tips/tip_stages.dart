/// The pictures the tips are built around.
///
/// Each stage is a loop over one gesture, driven by a `t` running 0 to 1 that
/// the tip page owns — the same `t` that lights the step being demonstrated in
/// the prose underneath, so the picture and the words never drift apart.
library;

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/utils/entity_icons.dart';

import 'watch_mock.dart';

/// How far through a phase [t] is, clamped outside it.
double _phase(double t, double from, double to) =>
    ((t - from) / (to - from)).clamp(0.0, 1.0);

const _groceries = Icons.local_grocery_store_outlined;

// -- Pairing -----------------------------------------------------------------

/// The handoff: the watch asks, the phone answers, the watch has a household.
class PairStage extends StatelessWidget {
  final double t;

  const PairStage({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final asking = t < 0.30;
    final travelling = t >= 0.26 && t < 0.46;
    final answered = t >= 0.74;

    // Shrink-wrapped: the stage is measured inside a FittedBox, which offers
    // no width to divide, and both devices are drawn at a fixed size anyway.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        WatchMock(
          size: 132,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: answered
                    ? const _SignedInFace(key: ValueKey('signed-in'))
                    : const _SetupFace(key: ValueKey('setup')),
              ),
              if (asking)
                TapCue(
                  t: _phase(t, 0.04, 0.28),
                  alignment: const Alignment(0, 0.37),
                ),
            ],
          ),
        ),
        _Link(active: travelling, progress: _phase(t, 0.26, 0.46)),
        PhoneMock(
          height: 128,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: t < 0.44
                    ? const _PhoneWaiting(key: ValueKey('waiting'))
                    : answered
                    ? const _PhonePaired(key: ValueKey('paired'))
                    : const _PhoneRequest(key: ValueKey('request')),
              ),
              if (t >= 0.52 && t < 0.76)
                TapCue(
                  t: _phase(t, 0.52, 0.76),
                  alignment: const Alignment(0.45, 0.02),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The dots between the two devices, and the one running along them.
class _Link extends StatelessWidget {
  final bool active;
  final double progress;

  const _Link({required this.active, required this.progress});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 34,
      height: 12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 4; i++)
                Container(
                  width: 3,
                  height: 3,
                  margin: const EdgeInsetsDirectional.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          if (active)
            _SlideAlong(
              progress: progress,
              child: _Spark(color: scheme.primary),
            ),
        ],
      ),
    );
  }
}

/// Slides its child from the start edge to the end edge as [progress] runs.
class _SlideAlong extends StatelessWidget {
  final double progress;
  final Widget child;

  const _SlideAlong({required this.progress, required this.child});

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional(
      progress * 2 - 1,
      0,
    ).resolve(Directionality.of(context)),
    child: child,
  );
}

class _Spark extends StatelessWidget {
  final Color color;

  const _Spark({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6),
      ],
    ),
  );
}

class _SetupFace extends StatelessWidget {
  const _SetupFace({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.watch_outlined, size: 18, color: scheme.primary),
          const SizedBox(height: 5),
          Text(
            m.wear.setupTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF2F2F4),
            ),
          ),
          const SizedBox(height: 10),
          MockCta(icon: Icons.phonelink_ring, label: m.wear.openOnPhone),
        ],
      ),
    );
  }
}

class _SignedInFace extends StatelessWidget {
  const _SignedInFace({super.key});

  @override
  Widget build(BuildContext context) => MockFace(
    rail: MockRail(
      title: m.onboarding.mockListGroceries,
      icon: _groceries,
      page: 0,
    ),
    body: MockItemList(items: _pantryItems, centre: 1),
  );
}

class _PhoneWaiting extends StatelessWidget {
  const _PhoneWaiting({super.key});

  @override
  Widget build(BuildContext context) => _PhoneScaffold(
    child: Center(
      child: Icon(
        Icons.watch_outlined,
        size: 22,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _PhoneRequest extends StatelessWidget {
  const _PhoneRequest({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _PhoneScaffold(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(6),
        child: Container(
          padding: const EdgeInsetsDirectional.all(6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                m.watch.requestTitle(m.watch.unnamedWatch),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 7.5,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              // Scaled to fit rather than laid out to fit: the card is a fixed
              // 74 pixels wide and the two verbs are translated, so the pair
              // is wider in some locales than any spacing here could absorb.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd.resolve(
                  Directionality.of(context),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      m.watch.deny,
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        m.watch.allow,
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhonePaired extends StatelessWidget {
  const _PhonePaired({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _PhoneScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 18, color: scheme.primary),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 6),
            child: Text(
              m.watch.pairedStatus,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The phone's own furniture, so the two devices read as different machines.
class _PhoneScaffold extends StatelessWidget {
  final Widget child;

  const _PhoneScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          height: 16,
          width: double.infinity,
          color: scheme.surfaceContainerHighest,
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsetsDirectional.only(start: 5),
          child: Text(
            m.watch.title,
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

// -- Items -------------------------------------------------------------------

List<MockItem> get _pantryItems => [
  MockItem(m.onboarding.mockBulkItemFourth),
  MockItem(m.onboarding.mockItemName, trailing: m.onboarding.mockItemQuantity),
  MockItem(m.onboarding.mockBulkItemThird),
  MockItem(m.onboarding.mockHardwareItemName),
];

/// A tap that checks, the window it stays reversible in, and the hold that
/// opens the item instead.
class ItemsStage extends StatelessWidget {
  final double t;

  const ItemsStage({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final checked = t >= 0.14;
    final undo = t < 0.14
        ? null
        : t < 0.48
        ? 1 - _phase(t, 0.14, 0.48)
        : null;
    final detail = _phase(t, 0.66, 0.73) * (1 - _phase(t, 0.97, 1.0));

    final items = [
      for (var i = 0; i < _pantryItems.length; i++)
        if (i == 1)
          MockItem(
            _pantryItems[i].label,
            trailing: _pantryItems[i].trailing,
            checked: checked,
            undo: undo,
          )
        else
          _pantryItems[i],
    ];

    return WatchMock(
      child: Stack(
        fit: StackFit.expand,
        children: [
          MockFace(
            rail: MockRail(
              title: m.onboarding.mockListGroceries,
              icon: _groceries,
              group: m.onboarding.mockItemCategory,
            ),
            body: MockItemList(items: items, centre: 1),
          ),
          if (t < 0.14) TapCue(t: _phase(t, 0.0, 0.14)),
          if (t >= 0.24 && t < 0.44) TapCue(t: _phase(t, 0.24, 0.44)),
          if (t >= 0.50 && t < 0.68) HoldCue(t: _phase(t, 0.50, 0.68)),
          if (detail > 0)
            Positioned.fill(
              child: Opacity(opacity: detail, child: const _DetailFace()),
            ),
        ],
      ),
    );
  }
}

/// What a held row opens: the item, spelled out, and the hand-off to the phone.
class _DetailFace extends StatelessWidget {
  const _DetailFace();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: const Color(0xFF0B0B0C),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              m.onboarding.mockItemName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF2F2F4),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                _Pip(m.onboarding.mockItemQuantity),
                _Pip(m.onboarding.mockItemCategory, tint: scheme.primary),
              ],
            ),
            const SizedBox(height: 10),
            MockCta(icon: Icons.check_circle_outline, label: m.wear.markDone),
            const SizedBox(height: 5),
            MockCta(icon: Icons.phonelink, label: m.wear.openOnPhone),
          ],
        ),
      ),
    );
  }
}

class _Pip extends StatelessWidget {
  final String label;
  final Color? tint;

  const _Pip(this.label, {this.tint});

  @override
  Widget build(BuildContext context) {
    final color = tint ?? const Color(0xFFB6B6BE);
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 7.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// -- Pages -------------------------------------------------------------------

/// The pager walking its pages, and the edge swipe that backs out of one.
class PagesStage extends StatelessWidget {
  final double t;

  const PagesStage({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    // Two page turns, then a pause on the notes wall while the indicator is
    // what the prose is talking about.
    final position = _phase(t, 0.06, 0.26) + _phase(t, 0.32, 0.52);
    final overlay = _phase(t, 0.72, 0.80) * (1 - _phase(t, 0.84, 0.98));

    return WatchMock(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _PagerFace(position: position),
          if (overlay > 0)
            _SlidOverPage(
              // In from the end edge as it opens, back out that way as the
              // edge swipe pushes it off.
              offset: 1 - overlay,
            ),
          if (t >= 0.06 && t < 0.26)
            SwipeCue(t: _phase(t, 0.06, 0.26), travel: 78),
          if (t >= 0.32 && t < 0.52)
            SwipeCue(t: _phase(t, 0.32, 0.52), travel: 78),
          if (t >= 0.84 && t < 0.98)
            SwipeCue(
              t: _phase(t, 0.84, 0.98),
              towardsStart: false,
              travel: 110,
            ),
        ],
      ),
    );
  }
}

/// The pages side by side, translated by [position] pages.
class _PagerFace extends StatelessWidget {
  final double position;

  const _PagerFace({required this.position});

  @override
  Widget build(BuildContext context) {
    final page = position.round().clamp(0, 3);
    final titles = <RailSpec>[
      (
        label: m.onboarding.mockListGroceries,
        icon: _groceries,
        tint: null,
        group: m.onboarding.mockItemCategory,
      ),
      (
        label: m.nav.photoBoard,
        icon: EntityIcons.photos,
        tint: null,
        group: null,
      ),
      (
        label: m.nav.notesWall,
        icon: EntityIcons.notes,
        tint: null,
        group: null,
      ),
      (label: m.wear.account, icon: Icons.person, tint: null, group: null),
    ];
    final title = titles[page];

    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: Stack(
              children: [
                for (var i = 0; i < 4; i++)
                  PositionedDirectional(
                    start: (i - position) * constraints.maxWidth,
                    width: constraints.maxWidth,
                    top: 0,
                    bottom: 0,
                    child: _pageBody(i),
                  ),
              ],
            ),
          ),
          MockFace(
            rail: MockRail(
              title: title.label,
              icon: title.icon,
              group: title.group,
              page: page,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageBody(int index) => switch (index) {
    0 => MockItemList(items: _pantryItems, centre: 1),
    1 => const _PhotoBoard(),
    2 => const _NotesWall(),
    _ => const _AccountBody(),
  };
}

typedef RailSpec = ({String label, IconData icon, Color? tint, String? group});

class _PhotoBoard extends StatelessWidget {
  const _PhotoBoard();

  @override
  Widget build(BuildContext context) => Center(
    child: FractionallySizedBox(
      widthFactor: 0.74,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row = 0; row < 2; row++)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 5),
              child: Row(
                children: [
                  for (var col = 0; col < 2; col++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: col == 0 ? 5 : 0,
                        ),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: 0.06 + 0.03 * (row + col),
                            ),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            Icons.image_outlined,
                            size: 14,
                            color: Colors.white24,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _NotesWall extends StatelessWidget {
  const _NotesWall();

  @override
  Widget build(BuildContext context) => Center(
    child: FractionallySizedBox(
      widthFactor: 0.74,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final tint in const [
            Color(0xFFE8C46B),
            Color(0xFF8FC9A5),
            Color(0xFF9FB6E8),
          ])
            Container(
              height: 26,
              margin: const EdgeInsetsDirectional.only(bottom: 5),
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
              alignment: AlignmentDirectional.centerStart,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                height: 3,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _AccountBody extends StatelessWidget {
  const _AccountBody();

  @override
  Widget build(BuildContext context) => Center(
    child: FractionallySizedBox(
      widthFactor: 0.78,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person, size: 18, color: Colors.white54),
          const SizedBox(height: 8),
          MockRows([
            MockItem(m.wear.house, leading: Icons.home_outlined),
            MockItem(m.wear.settings, leading: Icons.tune),
          ]),
        ],
      ),
    ),
  );
}

/// A route pushed over the pager, mid-slide.
class _SlidOverPage extends StatelessWidget {
  /// 0 fully covering the pager, 1 fully off the end edge.
  final double offset;

  const _SlidOverPage({required this.offset});

  @override
  Widget build(BuildContext context) => FractionalTranslation(
    // Off towards the end edge, which is where an edge swipe pushes a route
    // in either reading direction.
    translation: Offset(
      offset * (Directionality.of(context) == TextDirection.rtl ? -1 : 1),
      0,
    ),
    child: const _DetailFace(),
  );
}

// -- Lists -------------------------------------------------------------------

/// The title tapped, the panel dropped, and the switcher it leads to.
class ListsStage extends StatelessWidget {
  final double t;

  const ListsStage({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final panel = _phase(t, 0.16, 0.32);
    final switcher = _phase(t, 0.60, 0.67) * (1 - _phase(t, 0.96, 1.0));

    return WatchMock(
      child: Stack(
        fit: StackFit.expand,
        children: [
          MockFace(
            rail: MockRail(
              title: m.onboarding.mockListGroceries,
              icon: _groceries,
              panel: panel == 0
                  ? null
                  : ClipRect(
                      child: Align(
                        heightFactor: panel,
                        child: Column(
                          children: [
                            MockRailButton(
                              icon: Icons.shopping_cart_checkout,
                              label: m.shopping.startShopping,
                              primary: true,
                            ),
                            const SizedBox(height: 5),
                            MockRailButton(
                              icon: EntityIcons.checklists,
                              label: m.wear.changeList,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            body: MockItemList(items: _pantryItems, centre: 1),
          ),
          if (t < 0.16)
            TapCue(
              t: _phase(t, 0.0, 0.16),
              alignment: const Alignment(0, -0.72),
            ),
          if (t >= 0.44 && t < 0.60)
            TapCue(
              t: _phase(t, 0.44, 0.60),
              alignment: const Alignment(0, 0.01),
            ),
          if (switcher > 0)
            Positioned.fill(
              child: Opacity(opacity: switcher, child: const _SwitcherFace()),
            ),
        ],
      ),
    );
  }
}

class _SwitcherFace extends StatelessWidget {
  const _SwitcherFace();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: const Color(0xFF0B0B0C),
      child: MockFace(
        body: Center(
          child: FractionallySizedBox(
            widthFactor: 0.82,
            child: MockRows([
              MockItem(
                m.checklists.allLists,
                leading: EntityIcons.checklists,
                tint: scheme.primary,
              ),
              MockItem(m.onboarding.mockListGroceries, leading: _groceries),
              MockItem(
                m.onboarding.mockListHardware,
                leading: Icons.hardware_outlined,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// -- Shopping ----------------------------------------------------------------

/// A trip from the button that starts it to the tally that closes it.
class ShoppingStage extends StatelessWidget {
  final double t;

  const ShoppingStage({super.key, required this.t});

  @override
  Widget build(BuildContext context) => WatchMock(
    child: Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _scene(context),
        ),
        if (t < 0.16)
          TapCue(
            t: _phase(t, 0.02, 0.16),
            alignment: const Alignment(0, -0.31),
          ),
        if (t >= 0.40 && t < 0.54) const TapCue(t: 0.5),
        if (t >= 0.86 && t < 0.98)
          TapCue(t: _phase(t, 0.86, 0.98), alignment: const Alignment(0, 0.71)),
      ],
    ),
  );

  Widget _scene(BuildContext context) {
    if (t < 0.18) return const _BeforeTrip(key: ValueKey('before'));
    if (t < 0.36) return const _TripProgression(key: ValueKey('progression'));
    if (t < 0.58) {
      return _TripChecklist(key: const ValueKey('checklist'), t: t);
    }
    if (t < 0.78) return const _TillFace(key: ValueKey('till'));
    return const _SummaryFace(key: ValueKey('summary'));
  }
}

class _BeforeTrip extends StatelessWidget {
  const _BeforeTrip({super.key});

  @override
  Widget build(BuildContext context) => MockFace(
    rail: MockRail(
      title: m.onboarding.mockListGroceries,
      icon: _groceries,
      panel: MockRailButton(
        icon: Icons.shopping_cart_checkout,
        label: m.shopping.startShopping,
        primary: true,
      ),
    ),
    body: MockItemList(items: _pantryItems, centre: 1),
  );
}

class _TripProgression extends StatelessWidget {
  const _TripProgression({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MockFace(
      rail: MockRail(
        title: m.onboarding.shoppingMockStoreActive,
        icon: EntityIcons.store,
        group: m.wear.progression,
        page: 0,
        pages: 5,
      ),
      body: Center(
        child: FractionallySizedBox(
          widthFactor: 0.82,
          child: MockRows([
            MockItem(
              m.onboarding.shoppingMockStoreActive,
              leading: EntityIcons.store,
              tint: scheme.primary,
              trailing: m.wear.hereNow,
            ),
            MockItem(
              m.onboarding.shoppingMockStoreNext,
              leading: EntityIcons.store,
            ),
          ]),
        ),
      ),
      cta: MockCta(
        icon: Icons.arrow_forward,
        label: m.wear.nextIs(m.onboarding.shoppingMockStoreNext),
      ),
    );
  }
}

class _TripChecklist extends StatelessWidget {
  final double t;

  const _TripChecklist({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final ticked = t >= 0.48;
    final items = [
      for (var i = 0; i < _pantryItems.length; i++)
        if (i == 1)
          MockItem(
            _pantryItems[i].label,
            trailing: _pantryItems[i].trailing,
            checked: ticked,
            undo: ticked && t < 0.56 ? 1 - _phase(t, 0.48, 0.56) : null,
          )
        else
          MockItem(_pantryItems[i].label, checked: i == 0),
    ];
    return MockFace(
      rail: MockRail(
        title: m.onboarding.shoppingMockStoreActive,
        icon: EntityIcons.store,
        group: m.onboarding.mockItemCategory,
        page: 1,
        pages: 5,
      ),
      body: MockItemList(items: items, centre: 1),
    );
  }
}

class _TillFace extends StatelessWidget {
  const _TillFace({super.key});

  @override
  Widget build(BuildContext context) => MockFace(
    body: Center(
      child: FractionallySizedBox(
        widthFactor: 0.74,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              m.onboarding.shoppingMockStoreActive,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF2F2F4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '24.80',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF2F2F4),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    cta: MockCta(
      icon: Icons.arrow_forward,
      label: m.wear.nextIs(m.onboarding.shoppingMockStoreNext),
    ),
  );
}

class _SummaryFace extends StatelessWidget {
  const _SummaryFace({super.key});

  @override
  Widget build(BuildContext context) => MockFace(
    body: Center(
      child: FractionallySizedBox(
        widthFactor: 0.78,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              m.wear.boughtTally(6),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF2F2F4),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              m.wear.storeTally(2),
              style: const TextStyle(fontSize: 9, color: Color(0xFF9A9AA2)),
            ),
          ],
        ),
      ),
    ),
    cta: MockCta(
      icon: Icons.done_all,
      label: m.shopping.finishTrip,
      warning: true,
    ),
  );
}

// -- Crown -------------------------------------------------------------------

/// A turn walking the list, and the setting that hands it to the pager.
class CrownStage extends StatelessWidget {
  final double t;

  const CrownStage({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final scrolling = t < 0.52;
    final centre = 1 + 2 * _phase(t, 0.08, 0.44);
    final position = _phase(t, 0.78, 0.94);
    final settings = _phase(t, 0.56, 0.61) * (1 - _phase(t, 0.72, 0.76));

    return WatchMock(
      crownLit: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (scrolling)
            MockFace(
              rail: MockRail(
                title: m.onboarding.mockListGroceries,
                icon: _groceries,
              ),
              body: MockItemList(items: _pantryItems, centre: centre),
            )
          else
            _PagerFace(position: position),
          if (settings > 0)
            Positioned.fill(
              child: Opacity(opacity: settings, child: const _CrownSettings()),
            ),
          if (t >= 0.06 && t < 0.46)
            CrownCue(t: _phase(t, 0.06, 0.46), size: 182),
          if (t >= 0.76 && t < 0.96)
            CrownCue(t: _phase(t, 0.76, 0.96), size: 182),
        ],
      ),
    );
  }
}

class _CrownSettings extends StatelessWidget {
  const _CrownSettings();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: const Color(0xFF0B0B0C),
      child: MockFace(
        rail: MockRail(title: m.wear.crown, icon: Icons.tune, pages: 1),
        body: Center(
          child: FractionallySizedBox(
            widthFactor: 0.8,
            child: MockRows([
              MockItem(
                m.wear.crownScrollsList,
                leading: Icons.radio_button_unchecked,
              ),
              MockItem(
                m.wear.crownTurnsPages,
                leading: Icons.radio_button_checked,
                tint: scheme.primary,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// -- Offline -----------------------------------------------------------------

/// The rail's own answer to "is any of this saved?".
class OfflineStage extends StatelessWidget {
  final double t;

  const OfflineStage({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    // Two taps go into the queue, then the queue drains.
    final queued = t < 0.34
        ? 0
        : t < 0.46
        ? 1
        : t < 0.72
        ? 2
        : t < 0.82
        ? 1
        : 0;
    final items = [
      for (var i = 0; i < _pantryItems.length; i++)
        MockItem(
          _pantryItems[i].label,
          trailing: _pantryItems[i].trailing,
          checked: (i == 1 && t >= 0.34) || (i == 2 && t >= 0.46),
        ),
    ];

    return WatchMock(
      child: Stack(
        fit: StackFit.expand,
        children: [
          MockFace(
            rail: MockRail(
              title: m.onboarding.mockListGroceries,
              icon: _groceries,
              queued: queued,
              group: queued == 0 && t > 0.85 ? m.wear.allSaved : null,
            ),
            body: MockItemList(items: items, centre: 1),
          ),
          if (t >= 0.24 && t < 0.36)
            TapCue(
              t: _phase(t, 0.24, 0.36),
              alignment: const Alignment(0, -0.16),
            ),
          if (t >= 0.38 && t < 0.50)
            TapCue(
              t: _phase(t, 0.38, 0.50),
              alignment: const Alignment(0, 0.18),
            ),
        ],
      ),
    );
  }
}

// -- Tile --------------------------------------------------------------------

/// The swipe from the watch face to the tile that names your lists.
class TileStage extends StatelessWidget {
  final double t;

  const TileStage({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final position = _phase(t, 0.10, 0.34) + _phase(t, 0.44, 0.62);

    return WatchMock(
      child: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => ClipRect(
              child: Stack(
                children: [
                  for (var i = 0; i < 3; i++)
                    PositionedDirectional(
                      start: (i - position) * constraints.maxWidth,
                      width: constraints.maxWidth,
                      top: 0,
                      bottom: 0,
                      child: switch (i) {
                        0 => const _ClockFace(),
                        1 => const _AddTileFace(),
                        _ => const _PantryTileFace(),
                      },
                    ),
                ],
              ),
            ),
          ),
          if (t >= 0.10 && t < 0.34)
            SwipeCue(t: _phase(t, 0.10, 0.34), travel: 84),
          if (t >= 0.44 && t < 0.62)
            SwipeCue(t: _phase(t, 0.44, 0.62), travel: 84),
          if (t >= 0.70 && t < 0.92)
            TapCue(
              t: _phase(t, 0.70, 0.92),
              alignment: const Alignment(0, -0.08),
            ),
        ],
      ),
    );
  }
}

class _ClockFace extends StatelessWidget {
  const _ClockFace();

  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      '10:09',
      style: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w300,
        letterSpacing: 1,
        color: Color(0xFFF2F2F4),
      ),
    ),
  );
}

class _AddTileFace extends StatelessWidget {
  const _AddTileFace();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: const Icon(Icons.add, size: 22, color: Colors.white54),
    ),
  );
}

class _PantryTileFace extends StatelessWidget {
  const _PantryTileFace();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              m.common.appTitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            MockRows([
              MockItem(m.onboarding.mockListGroceries, leading: _groceries),
              MockItem(
                m.onboarding.mockListHardware,
                leading: Icons.hardware_outlined,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
