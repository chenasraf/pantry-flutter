import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/utils/checklist_icons.dart';
import 'package:pantry_core/utils/store_icons.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../wear_shape.dart';
import 'checklist_page.dart';
import 'focus_list.dart';
import 'proto_checklist_data.dart';
import 'proto_data.dart';
import 'proto_mechanics.dart';
import 'proto_tuning.dart';

/// PROTOTYPE — the checklists page in both of the shells it lives in, to be
/// judged on a real watch and then thrown away.
///
/// The structure was settled by grilling, so this is not a set of rival
/// designs: it is one design with the parts that can only be judged on a
/// wrist left live. **Double-tap the rail** for the tuning page — the snap,
/// the falloff, the undo window, the centre-card expansion, grouping, chip
/// visibility, and the two mode switches.
///
/// A live session is a different pager, not a mode of this page: browse is
/// checklists · photos · notes · account, and a session replaces the first
/// three with progression · checklist · done · skipped, opening on the
/// checklist rather than on progression.
class ChecklistPrototype extends StatefulWidget {
  const ChecklistPrototype({super.key});

  @override
  State<ChecklistPrototype> createState() => _ChecklistPrototypeState();
}

class _ChecklistPrototypeState extends State<ChecklistPrototype> {
  final _tuning = ProtoTuning();
  final _geometry = ValueNotifier(const FocusGeometry());
  final _pageKey = GlobalKey<ChecklistPageState>();

  late PageController _pager;
  var _page = 0;
  var _mode = ChecklistMode.browse;
  var _items = List.of(protoChecklistItems);

  /// The mode transition holds input for a moment after the pager swaps, so a
  /// tap already descending cannot land on a page set that did not exist when
  /// the finger started moving.
  var _locked = false;
  Timer? _lockTimer;

  /// Stands in for `SyncQueue`: writes are queued, not lost, and the rail
  /// carries the depth rather than every row wearing a marker.
  var _offline = false;
  var _queued = 0;
  Timer? _drain;

  @override
  void initState() {
    super.initState();
    _pager = PageController();
    _tuning.addListener(_onTuning);
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _drain?.cancel();
    _tuning.removeListener(_onTuning);
    _tuning.dispose();
    _geometry.dispose();
    _pager.dispose();
    super.dispose();
  }

  void _onTuning() => setState(() {});

  List<Widget> get _pages => _mode == ChecklistMode.browse
      ? [
          _checklist(),
          _PhotosPage(tuning: _tuning, active: _page == 1),
          _NotesPage(tuning: _tuning, active: _page == 2),
          const _StubPage(title: 'Account', icon: Icons.person_outline),
        ]
      : [
          const _StubPage(
            title: 'Progression',
            icon: Icons.storefront_outlined,
            note: 'card 718',
          ),
          _checklist(),
          _CollectionPage(
            title: 'Done',
            items: _items.where((i) => i.done).toList(),
            empty: 'Nothing bought yet',
            onTap: (id) => _commit(id, false),
          ),
          _CollectionPage(
            title: 'Skipped',
            items: _items.where((i) => i.skipped).toList(),
            empty: 'Nothing skipped',
            onTap: _unskip,
          ),
          const _StubPage(title: 'Account', icon: Icons.person_outline),
        ];

  Widget _checklist() {
    final session = _mode == ChecklistMode.session;
    final visible = _items
        .where((i) => session ? !i.done && !i.skipped : !i.done)
        .toList();
    return ChecklistPage(
      key: _pageKey,
      tuning: _tuning,
      mode: _mode,
      items: visible,
      doneItems: session ? const [] : _items.where((i) => i.done).toList(),
      geometry: _geometry,
      active: _page == _checklistIndex,
      onCommit: _commit,
      onSkip: _skip,
    );
  }

  int get _checklistIndex => _mode == ChecklistMode.session ? 1 : 0;

  void _commit(int id, bool done) {
    setState(() {
      _items = [
        for (final i in _items)
          i.id == id ? i.copyWith(done: done, skipped: false) : i,
      ];
      if (_offline) _queued++;
    });
  }

  void _skip(int id) {
    setState(() {
      _items = [
        for (final i in _items) i.id == id ? i.copyWith(skipped: true) : i,
      ];
      if (_offline) _queued++;
    });
  }

  void _unskip(int id) {
    setState(() {
      _items = [
        for (final i in _items) i.id == id ? i.copyWith(skipped: false) : i,
      ];
      if (_offline) _queued++;
    });
  }

  void _setOffline(bool value) {
    setState(() => _offline = value);
    _tuning.update(() => _tuning.offline = value);
    _drain?.cancel();
    if (value) return;
    // Coming back online drains the queue rather than clearing it, so the
    // count is watchable rather than instantaneous.
    _drain = Timer.periodic(const Duration(milliseconds: 260), (t) {
      if (!mounted || _queued == 0) {
        t.cancel();
        return;
      }
      setState(() => _queued--);
    });
  }

  /// Resolve → swap → lock out. The undo windows resolve first so nothing is
  /// left half-committed against a page set that is about to be replaced.
  Future<void> _setMode(ChecklistMode next) async {
    if (next == _mode) return;
    _pageKey.currentState?.resolvePending(commit: true);
    final landing = next == ChecklistMode.session ? 1 : 0;
    _lockTimer?.cancel();
    final previous = _pager;
    setState(() {
      _mode = next;
      _locked = true;
      _page = landing;
      _pager = PageController(initialPage: landing);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The outgoing PageView is still mounted for this frame, so its
      // controller cannot be torn down until after it.
      previous.dispose();
      // `initialPage` is not enough: swapping a controller makes the new
      // ScrollPosition `absorb` the old one, which carries the previous pixel
      // offset across and discards the initial page. The dots read state and
      // the pager read the absorbed offset, so they disagreed by exactly the
      // landing index.
      if (!mounted || !_pager.hasClients) return;
      if (_pager.page?.round() != landing) _pager.jumpToPage(landing);
    });
    _tuning.update(() => _tuning.sessionActive = next == ChecklistMode.session);
    _lockTimer = Timer(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _locked = false);
    });
  }

  ThemeData _theme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      // Two planes, not one: the rail has to read as separate from the cards
      // that scroll under it.
      scaffoldBackgroundColor: const Color(0xFF0B0B0C),
      // Only the two ground planes are overridden. `primary` stays whatever
      // ThemingService seeded, so the watch wears the same accent as the phone
      // rather than a colour invented for the prototype.
      colorScheme: base.colorScheme.copyWith(
        surface: const Color(0xFF0B0B0C),
        surfaceContainerHighest: const Color(0xFF17171A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _theme(context),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFF0B0B0C),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final railHeight = WearShape.isRound ? h * 0.21 : h * 0.15;
              return IgnorePointer(
                ignoring: _locked,
                child: Stack(
                  children: [
                    // The list runs full height with the rail over it: the
                    // falloff measures from the *screen's* centre, and a
                    // column would move that line.
                    Positioned.fill(
                      child: EdgeAwarePageView(
                        controller: _pager,
                        page: _page,
                        onPageChanged: (p) => setState(() => _page = p),
                        children: _pages,
                      ),
                    ),
                    PositionedDirectional(
                      top: 0,
                      start: 0,
                      end: 0,
                      height: railHeight,
                      child: GestureDetector(
                        onDoubleTap: () => _openTuning(context),
                        child: ColoredBox(
                          color: const Color(0xFF0B0B0C),
                          child: ValueListenableBuilder(
                            valueListenable: _geometry,
                            builder: (context, geometry, _) => _Rail(
                              title: _mode == ChecklistMode.session
                                  ? protoSessionStore
                                  : protoListTitle,
                              titleIcon: _mode == ChecklistMode.session
                                  ? storeIcon(
                                      protoStoreIcons[protoSessionStore],
                                    )
                                  : checklistIcon(protoListIconKey),
                              titleColor: _mode == ChecklistMode.session
                                  ? (protoStoreColors[protoSessionStore] ??
                                        protoListColor)
                                  : protoListColor,
                              group: _page == _checklistIndex
                                  ? geometry.stickyGroup
                                  : null,
                              groupIcon: geometry.stickyIcon,
                              groupColor: geometry.stickyColor,
                              page: _page,
                              pages: _pages.length,
                              offline: _offline,
                              queued: _queued,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openTuning(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          TuningPage(tuning: _tuning, onMode: _setMode, onOffline: _setOffline),
    ),
  );
}

/// The list (or, in a session, the store), the focused card's group, sync and
/// the dots.
///
/// The house is deliberately absent: one household is the overwhelming case,
/// so naming it every frame spends the rail's scarcest line on something that
/// almost never changes. It lives on the account page, beside the control that
/// switches it.
///
/// The group label is the sticky half of the header: the header itself scrolls
/// up as an ordinary short row, and the rail takes it over as it slides under.
/// [push] is the next header arriving and shouldering the current label out.
class _Rail extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final Color titleColor;
  final String? group;
  final IconData? groupIcon;
  final Color? groupColor;
  final int page;
  final int pages;
  final bool offline;
  final int queued;

  const _Rail({
    required this.title,
    required this.titleIcon,
    required this.titleColor,
    required this.group,
    required this.groupIcon,
    required this.groupColor,
    required this.page,
    required this.pages,
    required this.offline,
    required this.queued,
  });

  @override
  Widget build(BuildContext context) {
    final window = dotWindow(pages, page);
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        widthFactor: WearShape.isRound ? 0.68 : 0.92,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (offline || queued > 0) ...[
                  Icon(
                    offline ? Icons.cloud_off : Icons.cloud_queue,
                    size: 10,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 4),
                  if (queued > 0)
                    Text(
                      '$queued waiting',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white54,
                      ),
                    ),
                ] else
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 6),
                Icon(titleIcon, size: 12, color: titleColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: detectTextDirection(title),
                    style: TextStyle(
                      fontSize: 11,
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 13,
              // Driven by the label changing, not by a header's distance from
              // the centre line. Those are different events: the header starts
              // approaching while the last row of the outgoing group is still
              // focused, so a geometric transition began a row early and had
              // nothing left to play when the new label actually arrived.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.7),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: group == null
                    ? const SizedBox.shrink()
                    : Row(
                        key: ValueKey(group),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (groupIcon != null) ...[
                            Icon(
                              groupIcon,
                              size: 10,
                              color: groupColor ?? Colors.white38,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              group!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: detectTextDirection(group!),
                              style: TextStyle(
                                fontSize: 9,
                                height: 1.1,
                                letterSpacing: 0.4,
                                fontWeight: FontWeight.w700,
                                color: groupColor ?? Colors.white38,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 3),
            // Bars, not dots: the current page grows into a line so the
            // indicator says *where* you are as well as how many there are,
            // and it animates rather than cutting between the two widths.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < window.count; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsetsDirectional.symmetric(
                      horizontal: 2,
                    ),
                    width: i == window.selected ? 14 : 8,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i == window.selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white24,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The done and skipped pages a session gets in place of photos and notes.
class _CollectionPage extends StatelessWidget {
  final String title;
  final List<ProtoChecklistItem> items;
  final String empty;
  final void Function(int id) onTap;

  const _CollectionPage({
    required this.title,
    required this.items,
    required this.empty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          empty,
          style: const TextStyle(fontSize: 12, color: Colors.white38),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsetsDirectional.only(
        top: MediaQuery.sizeOf(context).height * 0.24,
        bottom: 30,
        start: 16,
        end: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 5),
          child: GestureDetector(
            onTap: () => onTap(item.id),
            behavior: HitTestBehavior.opaque,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF17171A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: detectTextDirection(item.name),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white54,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                    const Icon(Icons.undo, size: 14, color: Colors.white38),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Photos read as a grid rather than a stack of full-width cards — a wrist is
/// scanning for the one it remembers, and two to a row halves how far it has
/// to scan. A *row* of tiles is what the centre line holds, so the focus
/// falloff applies to the row, not the tile. View only; the mirror carries no
/// bytes, so these are online-only.
class _PhotosPage extends StatefulWidget {
  final ProtoTuning tuning;
  final bool active;

  const _PhotosPage({required this.tuning, required this.active});

  @override
  State<_PhotosPage> createState() => _PhotosPageState();
}

class _PhotosPageState extends State<_PhotosPage> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = (protoPhotos.length / 2).ceil();
    return SnapFocusList(
      controller: _controller,
      itemExtent: 88,
      falloffRows: widget.tuning.falloffRows,
      snapEnabled: widget.tuning.snapEnabled,
      rotaryActive: widget.active,
      elements: [
        for (var row = 0; row < rows; row++)
          FocusElement(
            extent: 88,
            builder: (context, d) => Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(child: _tile(protoPhotos[row * 2])),
                  const SizedBox(width: 6),
                  Expanded(
                    child: row * 2 + 1 < protoPhotos.length
                        ? _tile(protoPhotos[row * 2 + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _tile(ProtoPhoto photo) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [photo.a, photo.b]),
      ),
      child: Align(
        alignment: AlignmentDirectional.bottomStart,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(6),
          child: Text(
            photo.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: detectTextDirection(photo.caption),
            style: const TextStyle(fontSize: 10),
          ),
        ),
      ),
    ),
  );
}

/// Notes ride the mirror whole, bodies included, so a note is readable on the
/// wrist without a fetch.
class _NotesPage extends StatefulWidget {
  final ProtoTuning tuning;
  final bool active;

  const _NotesPage({required this.tuning, required this.active});

  @override
  State<_NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<_NotesPage> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SnapFocusList(
      controller: _controller,
      itemExtent: 72,
      falloffRows: widget.tuning.falloffRows,
      snapEnabled: widget.tuning.snapEnabled,
      rotaryActive: widget.active,
      elements: [
        for (final note in protoNotes)
          FocusElement(
            extent: 72,
            builder: (context, d) => Center(
              child: SizedBox(
                height: 66,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      const Color(0xFF17171A),
                      const Color(0xFF121215),
                      d,
                    ),
                    borderRadius: BorderRadius.circular(
                      WearShape.isRound ? 18 : 12,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: detectTextDirection(note.title),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.1,
                            fontWeight: d < 0.5
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Expanded(
                          child: Text(
                            note.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textDirection: detectTextDirection(note.body),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white60,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StubPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? note;

  const _StubPage({required this.title, required this.icon, this.note});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 26, color: Colors.white24),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 13, color: Colors.white54),
        ),
        if (note != null)
          Text(
            note!,
            style: const TextStyle(fontSize: 9, color: Colors.white24),
          ),
      ],
    ),
  );
}

/// Everything the page could not settle off-hardware, in one place.
class TuningPage extends StatefulWidget {
  final ProtoTuning tuning;
  final ValueChanged<ChecklistMode> onMode;
  final ValueChanged<bool> onOffline;

  const TuningPage({
    super.key,
    required this.tuning,
    required this.onMode,
    required this.onOffline,
  });

  @override
  State<TuningPage> createState() => _TuningPageState();
}

class _TuningPageState extends State<TuningPage> {
  static const _chips = [
    'category',
    'store',
    'quantity',
    'price',
    'note',
    'recurring',
  ];

  /// This page is a pushed route, so it does not rebuild when the page beneath
  /// it does — it has to listen to the object it is mutating or its own
  /// controls go stale while the changes land underneath.
  @override
  void initState() {
    super.initState();
    widget.tuning.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.tuning.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tuning;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      body: EdgeDismissible(
        onDismiss: () => Navigator.of(context).pop(),
        child: ListView(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 44,
          ),
          children: [
            const _Heading('Session'),
            _toggle(
              'Live session',
              t.sessionActive,
              (v) => widget.onMode(
                v ? ChecklistMode.session : ChecklistMode.browse,
              ),
            ),
            _toggle('Offline', t.offline, widget.onOffline),
            const _Heading('List'),
            _toggle(
              'Snap',
              t.snapEnabled,
              (v) => t.update(() => t.snapEnabled = v),
            ),
            _toggle(
              'Wheel (the 714 control)',
              t.useWheel,
              (v) => t.update(() => t.useWheel = v),
            ),
            _toggle(
              'Expand centre card',
              t.expandCentre,
              (v) => t.update(() => t.expandCentre = v),
            ),
            _slider(
              'Undo ${t.undoMs}ms',
              t.undoMs.toDouble(),
              600,
              4000,
              (v) => t.update(() => t.undoMs = v.round()),
            ),
            _slider(
              'Falloff ${t.falloffRows.toStringAsFixed(1)} rows',
              t.falloffRows,
              1,
              5,
              (v) => t.update(() => t.falloffRows = v),
            ),
            _slider(
              'Row ${t.itemExtent.round()}px',
              t.itemExtent,
              44,
              72,
              (v) => t.update(() => t.itemExtent = v),
            ),
            _slider(
              'Card gap ${t.cardGap.round()}px',
              t.cardGap,
              0,
              16,
              (v) => t.update(() => t.cardGap = v),
            ),
            _slider(
              'Header ${t.headerExtent.round()}px',
              t.headerExtent,
              14,
              48,
              (v) => t.update(() => t.headerExtent = v),
            ),
            const _Heading('Grouping'),
            for (final g in GroupBy.values)
              _toggle(
                g.name,
                t.groupBy == g,
                (_) => t.update(() => t.groupBy = g),
              ),
            const _Heading('Chips'),
            for (final key in _chips)
              _toggle(key, t.isChipVisible(key), (_) => t.toggleChip(key)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) =>
      GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 5),
          child: Row(
            children: [
              Icon(
                value ? Icons.check_box : Icons.check_box_outline_blank,
                size: 16,
                color: value
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white38,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) => Padding(
    padding: const EdgeInsetsDirectional.only(top: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
        SizedBox(
          height: 26,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              activeColor: Theme.of(context).colorScheme.primary,
              inactiveColor: Colors.white24,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Heading extends StatelessWidget {
  final String text;

  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(top: 12, bottom: 3),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 9,
        letterSpacing: 0.9,
        fontWeight: FontWeight.w700,
        color: Colors.white38,
      ),
    ),
  );
}
