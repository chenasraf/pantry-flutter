import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/utils/checklist_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/entity_icons.dart';
import 'package:pantry_core/utils/store_icons.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../account/account_page.dart';
import '../checklists/checklists_controller.dart';
import '../checklists/checklists_page.dart';
import '../checklists/list_switcher_page.dart';
import '../photos/photos_page.dart';
import '../notes/notes_page.dart';
import '../services/rotary_service.dart';
import '../services/wear_deep_link.dart';
import '../shopping/progression_page.dart';
import '../shopping/start_trip_page.dart';
import '../shopping/trip_collection_page.dart';
import '../widgets/focus_list.dart';
import '../widgets/wear_ink.dart';
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

  late PageController _pager;
  var _page = 0;
  var _mode = ChecklistMode.browse;

  /// The mode transition holds input for a moment after the pager swaps, so a
  /// tap already descending cannot land on a page set that did not exist when
  /// the finger started moving.
  var _locked = false;
  Timer? _lockTimer;

  /// True until the controller's first cache read resolves. `mode` derives from
  /// the trip, and the trip is read from the cache — so at `initState` it is
  /// always `browse`, and a watch woken mid-shop would draw the empty browse
  /// checklist and then swap off it. Nothing is drawn over that gap instead,
  /// which is microtasks rather than frames: the stores are loaded before
  /// `runApp` and the read touches no network.
  var _awaitingFirstRead = false;

  /// A route pushed over the pager takes the crown with it: the detent stream
  /// is broadcast and a covered page stays mounted, so leaving it subscribed
  /// means one turn of the bezel scrolls two lists.
  var _routeOpen = false;

  /// What the wearer has said a turn of the bezel steers. Cached rather than
  /// read in `build`, so the pages are rebuilt when it changes and not on every
  /// other pref written anywhere in the app.
  var _crownTurnsPages = false;

  /// The shell's own subscription, held only while the crown turns pages —
  /// exactly the times no page holds one.
  StreamSubscription<double>? _rotary;

  /// Where the last detent was heading, so a fast turn accumulates pages
  /// instead of each detent re-measuring against one still in flight.
  int? _pageTarget;

  /// Whether anything is drawn over the shell. [_routeOpen] only knows about
  /// the routes the shell itself pushes; a page pushing its own route is
  /// invisible to it, and in page mode that would leave the shell turning
  /// pages under a route that is scrolling its own list. The navigator is
  /// asked instead, which knows about both.
  var _uncovered = true;

  var _railExpanded = false;
  Timer? _railTimer;

  String? _notice;
  Timer? _noticeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = widget.controller ?? ChecklistsController();
    _awaitingFirstRead = _controller.isLoading;
    _adoptMode(_controller.mode);
    _crownTurnsPages = PrefsService.instance.wearCrownTurnsPages;
    _controller.addListener(_onData);
    PrefsService.instance.addListener(_onPrefs);
    WearDeepLink.instance.addListener(_onDeepLink);
    if (widget.controller == null) unawaited(_controller.start());
  }

  /// `isCurrent` is carried on an inherited widget, so reading it here is also
  /// what has this called again when a route is pushed or popped over us.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _uncovered = ModalRoute.of(context)?.isCurrent ?? true;
    _syncRotary();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WearDeepLink.instance.removeListener(_onDeepLink);
    PrefsService.instance.removeListener(_onPrefs);
    _rotary?.cancel();
    _lockTimer?.cancel();
    _railTimer?.cancel();
    _noticeTimer?.cancel();
    _controller.removeListener(_onData);
    // Only the one this shell made: an injected controller outlives it.
    if (widget.controller == null) _controller.dispose();
    _geometry.dispose();
    _pager.dispose();
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
    // The first read settling is the shell opening, not a mode change: no
    // pager has been drawn, so the mode it lands on is taken on outright
    // rather than swapped into behind a lockout.
    if (_awaitingFirstRead && !_controller.isLoading) {
      _awaitingFirstRead = false;
      final previous = _pager;
      setState(() => _adoptMode(_controller.mode));
      // Never attached to a PageView — the gate is what kept one from being
      // built — so unlike _setMode's swap this needs no frame to outlive.
      previous.dispose();
      return;
    }
    if (_controller.mode != _mode) {
      unawaited(_setMode(_controller.mode));
      return;
    }
    setState(() {});
  }

  /// Take a mode on with no transition: its landing page, and a pager already
  /// opening there. Correct only while nothing is on screen — a mounted
  /// `PageView` needs [_setMode]'s swap instead.
  void _adoptMode(ChecklistMode next) {
    _mode = next;
    _page = next == ChecklistMode.session ? 1 : 0;
    _pager = PageController(initialPage: _page);
  }

  /// A Tile tap landing on an app that is already up. The launch case is
  /// applied before `runApp` and never reaches here.
  ///
  /// Scope moves, and the pager follows it to the page that shows a list —
  /// arriving from the Tile onto the notes page would leave the wearer looking
  /// at the one thing they did not ask for.
  Future<void> _onDeepLink() async {
    if (!await WearDeepLink.instance.applyPending()) return;
    if (!mounted) return;
    final landing = _checklistIndex;
    if (_page == landing || !_pager.hasClients) return;
    _pager.jumpToPage(landing);
  }

  void _showNotice(String message) {
    setState(() => _notice = message);
    _noticeTimer?.cancel();
    _noticeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _notice = null);
    });
  }

  // -- The crown -------------------------------------------------------------

  void _onPrefs() {
    final next = PrefsService.instance.wearCrownTurnsPages;
    if (next == _crownTurnsPages) return;
    setState(() => _crownTurnsPages = next);
    _syncRotary();
  }

  /// Exactly one reader of the detent stream, always. In page mode that is the
  /// shell and every page has gone quiet; otherwise it is the page in front,
  /// or the route standing over it.
  void _syncRotary() {
    final wanted = _crownTurnsPages && _uncovered;
    if (wanted == (_rotary != null)) return;
    _rotary?.cancel();
    _rotary = wanted ? RotaryService.instance.detents.listen(_onDetent) : null;
    _pageTarget = null;
  }

  /// The axis reports the opposite of what the wrist means: turning the bezel
  /// clockwise reads negative, and clockwise has to go to the next page.
  ///
  /// The step is one page and the snap table has nothing to say about it —
  /// stepping the table is a rule about a list, where a short header between
  /// two rows makes a fixed pixel step walk off the grid.
  void _onDetent(double detent) {
    if (_locked || !_pager.hasClients) return;
    final from = _pageTarget ?? _page;
    final next = (from + (detent < 0 ? 1 : -1)).clamp(0, _pages.length - 1);
    if (next == from) return;
    _pageTarget = next;
    unawaited(
      _pager
          .animateToPage(
            next,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          )
          .whenComplete(() => _pageTarget = null),
    );
  }

  int get _checklistIndex => _mode == ChecklistMode.session ? 1 : 0;

  /// Last of either page set — a page, not a route, so following the rail's
  /// degraded signpost is a pager move rather than a push.
  int get _accountIndex => _mode == ChecklistMode.session ? 4 : 3;

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
          PhotosPage(active: _isActive(1), rotary: _steersList(1)),
          NotesPage(
            active: _isActive(2),
            rotary: _steersList(2),
            onNotice: _showNotice,
          ),
          AccountPage(rotary: _steersList(3)),
        ]
      : [
          ProgressionPage(
            controller: _controller,
            active: _isActive(0),
            rotary: _steersList(0),
          ),
          _checklists(),
          TripCollectionPage(
            controller: _controller,
            items: _controller.done,
            empty: m.wear.nothingToCheckOff,
            markedIcon: Icons.check_circle,
            onTap: _controller.uncheckItem,
            rotary: _steersList(2),
          ),
          TripCollectionPage(
            controller: _controller,
            items: _controller.removed,
            empty: m.wear.nothingRemoved,
            markedIcon: Icons.remove_shopping_cart,
            onTap: _controller.unskipItem,
            rotary: _steersList(3),
          ),
          AccountPage(rotary: _steersList(4)),
        ];

  bool _isActive(int index) => _page == index && !_routeOpen;

  /// The page the crown scrolls: the one in front, and only while scrolling is
  /// what the crown does. With it turning pages instead, every page goes quiet
  /// and the shell is the one reader.
  bool _steersList(int index) => _isActive(index) && !_crownTurnsPages;

  Widget _checklists() => ChecklistsPage(
    key: _pageKey,
    controller: _controller,
    geometry: _geometry,
    rotary: _steersList(_checklistIndex),
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

  // -- The rail's buttons ----------------------------------------------------

  /// Tapping the rail expands it; the buttons it reveals are what act.
  /// Untouched, the expansion collapses on its own.
  ///
  /// Two buttons take longer to read than one, so the window is wide enough to
  /// read them and still short enough that the rail is not left standing over
  /// the list.
  void _tapRail() {
    if (_mode == ChecklistMode.session || _page != _checklistIndex) return;
    _railTimer?.cancel();
    setState(() => _railExpanded = !_railExpanded);
    if (!_railExpanded) return;
    _railTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) setState(() => _railExpanded = false);
    });
  }

  /// Following the degraded line. It animates rather than jumping: the wearer
  /// tapped a signpost and the movement is what tells them the tap was read.
  void _showAccount() {
    _railTimer?.cancel();
    setState(() => _railExpanded = false);
    if (_page == _accountIndex || !_pager.hasClients) return;
    _pager.animateToPage(
      _accountIndex,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  /// A route pushed over the pager takes the crown with it, and the rail
  /// collapses behind it — an expansion the wearer has already acted on has
  /// nothing left to offer when they come back.
  Future<T?> _push<T>(Widget page) async {
    _railTimer?.cancel();
    setState(() {
      _railExpanded = false;
      _routeOpen = true;
    });
    final result = await Navigator.of(context).push<T>(wearRoute<T>(page));
    if (mounted) setState(() => _routeOpen = false);
    return result;
  }

  Future<void> _openSwitcher() => _push<void>(
    ListSwitcherPage(
      lists: _controller.lists,
      selectedId: _controller.list?.id,
    ),
  );

  /// Starting a trip is a pushed page, not a rail control: it has four things
  /// to choose between and a wearer has to be able to leave it having chosen
  /// none of them.
  ///
  /// A started trip is read back rather than handed over — the shell swaps its
  /// page set on the controller's mode, and the controller's own refresh is
  /// what settles it, so there is one path into a session however it began.
  Future<void> _openStartTrip() async {
    final house = _controller.houseId;
    if (house == null) return;
    final started = await _push<bool>(StartTripPage(houseId: house));
    if (started == true) unawaited(_controller.refresh());
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
    // The ground plane the pager arrives on, so there is no colour step when
    // it does. Nothing is said over it: the wait is shorter than a spinner
    // would take to become legible, and a flash of one reads as a fault.
    if (_awaitingFirstRead) {
      return const ColoredBox(color: wearGround, child: SizedBox.expand());
    }
    return Theme(
      data: _theme(context),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFF0B0B0C),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final railHeight = WearMetrics.railHeight(h);
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
                    // The rail sizes itself: expanding costs height, and it is
                    // the rail that knows what its own buttons need.
                    PositionedDirectional(
                      top: 0,
                      start: 0,
                      end: 0,
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
                          baseHeight: railHeight,
                          expanded: _railExpanded,
                          onTapTitle: _tapRail,
                          onChangeList: _openSwitcher,
                          onStartShopping: _mode == ChecklistMode.browse
                              ? _openStartTrip
                              : null,
                          onSetUpAgain: _showAccount,
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
        color: wearNoticeGround,
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
          style: const TextStyle(fontSize: 10, color: wearNoticeInk),
        ),
      ),
    ),
  );
}
