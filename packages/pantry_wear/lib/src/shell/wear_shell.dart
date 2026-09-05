import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/utils/checklist_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/entity_icons.dart';
import 'package:pantry_core/utils/store_icons.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../checklists/checklists_controller.dart';
import '../checklists/checklists_page.dart';
import '../checklists/list_switcher_page.dart';
import '../prototype/notes_page.dart';
import '../prototype/photos_page.dart';
import '../prototype/proto_tuning.dart';
import '../wear_shape.dart';
import '../widgets/focus_list.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import 'wear_rail.dart';

/// The livery of a page that is not a list. A list wears its own colour, so
/// anything else taking one would read as an identity it does not have.
const _chrome = Color(0xFFB6B6BE);

/// The watch's shell: a rail over a pager of full-height pages.
///
/// Browsing is checklists · photos · notes · account. A live session replaces
/// the first three with progression · checklist · done · skipped and opens on
/// the checklist rather than on progression, so the page you need while
/// walking an aisle is the one already under your thumb.
class WearShell extends StatefulWidget {
  /// Supplied only by tests, which pump the real tree against a controller
  /// holding a fixed answer. The shell starts the one it makes itself.
  final ChecklistsController? controller;

  const WearShell({super.key, this.controller});

  @override
  State<WearShell> createState() => _WearShellState();
}

class _WearShellState extends State<WearShell> with WidgetsBindingObserver {
  late final ChecklistsController _controller;
  final _geometry = ValueNotifier(const FocusGeometry());
  final _pageKey = GlobalKey<ChecklistsPageState>();

  /// The photos and notes pages are still the design skeleton, drawn from
  /// fixtures; each carries its own tuning until it is built against the
  /// server.
  final _skeletonTuning = ProtoTuning();

  late PageController _pager;
  var _page = 0;
  var _mode = ChecklistMode.browse;

  /// The mode transition holds input for a moment after the pager swaps, so a
  /// tap already descending cannot land on a page set that did not exist when
  /// the finger started moving.
  var _locked = false;
  Timer? _lockTimer;

  /// A route pushed over the pager takes the crown with it: the detent stream
  /// is broadcast and a covered page stays mounted, so leaving it subscribed
  /// means one turn of the bezel scrolls two lists.
  var _routeOpen = false;

  var _railExpanded = false;
  Timer? _railTimer;

  String? _notice;
  Timer? _noticeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = widget.controller ?? ChecklistsController();
    _mode = _controller.mode;
    _page = _mode == ChecklistMode.session ? 1 : 0;
    _pager = PageController(initialPage: _page);
    _controller.addListener(_onData);
    if (widget.controller == null) unawaited(_controller.start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockTimer?.cancel();
    _railTimer?.cancel();
    _noticeTimer?.cancel();
    _controller.removeListener(_onData);
    // Only the one this shell made: an injected controller outlives it.
    if (widget.controller == null) _controller.dispose();
    _geometry.dispose();
    _pager.dispose();
    _skeletonTuning.dispose();
    super.dispose();
  }

  /// Pause-on-blur, and it is not an optimisation: a Dart timer keeps firing
  /// while the watch sleeps, so an unpaused poll runs for the whole time the
  /// screen is off.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.setActive(state == AppLifecycleState.resumed);
  }

  void _onData() {
    if (!mounted) return;
    final dropped = _controller.droppedMessage;
    if (dropped != null) {
      _showNotice(dropped);
      _controller.clearDropped();
    }
    if (_controller.mode != _mode) {
      unawaited(_setMode(_controller.mode));
      return;
    }
    setState(() {});
  }

  void _showNotice(String message) {
    setState(() => _notice = message);
    _noticeTimer?.cancel();
    _noticeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _notice = null);
    });
  }

  int get _checklistIndex => _mode == ChecklistMode.session ? 1 : 0;

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
    _lockTimer = Timer(WearMetrics.modeLockout, () {
      if (mounted) setState(() => _locked = false);
    });
  }

  // -- Pages -----------------------------------------------------------------

  List<Widget> get _pages => _mode == ChecklistMode.browse
      ? [
          _checklists(),
          PhotosPage(tuning: _skeletonTuning, active: _isActive(1)),
          NotesPage(tuning: _skeletonTuning, active: _isActive(2)),
          _StubPage(title: m.wear.account, icon: Icons.person),
        ]
      : [
          _StubPage(title: m.wear.progression, icon: EntityIcons.store),
          _checklists(),
          _CollectionPage(
            items: _controller.done,
            empty: m.wear.nothingToCheckOff,
            trailing: Icons.undo,
            onTap: _controller.uncheckItem,
          ),
          _CollectionPage(
            items: _controller.removed,
            empty: m.wear.nothingRemoved,
            trailing: Icons.undo,
            onTap: _controller.unskipItem,
          ),
          _StubPage(title: m.wear.account, icon: Icons.person),
        ];

  bool _isActive(int index) => _page == index && !_routeOpen;

  Widget _checklists() => ChecklistsPage(
    key: _pageKey,
    controller: _controller,
    geometry: _geometry,
    active: _isActive(_checklistIndex),
  );

  /// The rail names the page you are on, one entry per [_pages] entry.
  List<RailTitle> get _titles => _mode == ChecklistMode.browse
      ? [
          _listTitle,
          (label: m.nav.photoBoard, icon: EntityIcons.photos, color: _chrome),
          (label: m.nav.notesWall, icon: EntityIcons.notes, color: _chrome),
          (label: m.wear.account, icon: Icons.person, color: _chrome),
        ]
      : [
          (label: m.wear.progression, icon: EntityIcons.store, color: _chrome),
          _listTitle,
          (
            label: m.wear.done,
            icon: Icons.check_circle_outline,
            color: _chrome,
          ),
          (
            label: m.wear.skipped,
            icon: Icons.remove_shopping_cart_outlined,
            color: _chrome,
          ),
          (label: m.wear.account, icon: Icons.person, color: _chrome),
        ];

  /// A session names the store it is being shopped at, because that is the
  /// thing you are standing in; browsing names the list.
  RailTitle get _listTitle {
    final session = _controller.session;
    if (session != null) {
      final store = _controller.storeById(session.activeStoreId);
      if (store != null) {
        return (
          label: store.name,
          icon: storeIcon(store.icon),
          color: parseHexColor(store.color) ?? _chrome,
        );
      }
      return (
        label: m.shopping.anyStore,
        icon: EntityIcons.store,
        color: _chrome,
      );
    }
    final list = _controller.list;
    if (list == null) {
      return (
        label: m.nav.checklists,
        icon: EntityIcons.checklists,
        color: _chrome,
      );
    }
    return (
      label: list.name,
      icon: list.id == kAllListsId ? allListsIcon : checklistIcon(list.icon),
      color: parseHexColor(list.color) ?? _chrome,
    );
  }

  // -- The list switcher -----------------------------------------------------

  /// Tapping the rail expands it; the button it reveals is what opens the
  /// switcher. Untouched, the expansion collapses on its own.
  void _tapRail() {
    if (_mode == ChecklistMode.session || _page != _checklistIndex) return;
    _railTimer?.cancel();
    setState(() => _railExpanded = !_railExpanded);
    if (!_railExpanded) return;
    _railTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _railExpanded = false);
    });
  }

  Future<void> _openSwitcher() async {
    _railTimer?.cancel();
    setState(() {
      _railExpanded = false;
      _routeOpen = true;
    });
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListSwitcherPage(
          lists: _controller.lists,
          selectedId: _controller.list?.id,
        ),
      ),
    );
    if (mounted) setState(() => _routeOpen = false);
  }

  // -- Frame -----------------------------------------------------------------

  ThemeData _theme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      // Two planes, not one: the rail has to read as separate from the cards
      // that scroll under it.
      scaffoldBackgroundColor: const Color(0xFF0B0B0C),
      // Only the two ground planes are overridden. `primary` stays whatever
      // ThemingService seeded, so the watch wears the same accent as the phone
      // rather than a colour invented for it.
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
              final titles = _titles;
              // The pager can land mid-swap, one frame before the mode's page
              // set is the one being drawn.
              final title = titles[_page.clamp(0, titles.length - 1)];
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
                        onPageChanged: (p) => setState(() {
                          _page = p;
                          _railExpanded = false;
                        }),
                        children: _pages,
                      ),
                    ),
                    PositionedDirectional(
                      top: 0,
                      start: 0,
                      end: 0,
                      height: railHeight,
                      child: ColoredBox(
                        color: const Color(0xFF0B0B0C),
                        child: ValueListenableBuilder(
                          valueListenable: _geometry,
                          builder: (context, geometry, _) => WearRail(
                            title: title,
                            group: _page == _checklistIndex
                                ? geometry.stickyGroup
                                : null,
                            groupIcon: geometry.stickyIcon,
                            groupColor: geometry.stickyColor,
                            page: _page,
                            pages: _pages.length,
                            expanded: _railExpanded,
                            onTapTitle: _tapRail,
                            onChangeList: _openSwitcher,
                          ),
                        ),
                      ),
                    ),
                    if (_notice != null)
                      PositionedDirectional(
                        start: 0,
                        end: 0,
                        bottom: h * 0.08,
                        child: _Notice(message: _notice!),
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
}

/// The done and skipped pages a session gets in place of photos and notes.
class _CollectionPage extends StatelessWidget {
  final List<ListItem> items;
  final String empty;
  final IconData trailing;
  final void Function(ListItem item) onTap;

  const _CollectionPage({
    required this.items,
    required this.empty,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          empty,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.white38),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsetsDirectional.only(
        top: MediaQuery.sizeOf(context).height * 0.24,
        bottom: 30,
        start: 10,
        end: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 5),
          child: GestureDetector(
            onTap: () => onTap(item),
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
                    Icon(trailing, size: 14, color: Colors.white38),
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

/// A write the server refused, said once and then gone. A state with a
/// lifetime — no credentials, no connection — is a different thing and wears a
/// persistent banner instead.
class _Notice extends StatelessWidget {
  final String message;

  const _Notice({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF2A1D1D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          textDirection: detectTextDirection(message),
          style: const TextStyle(fontSize: 10, color: Color(0xFFE0A0A0)),
        ),
      ),
    ),
  );
}

class _StubPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const _StubPage({required this.title, required this.icon});

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
      ],
    ),
  );
}
