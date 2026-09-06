import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/house_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../widgets/wear_ink.dart';
import '../scope/wear_scope.dart';
import '../services/wear_mirror_client.dart';
import '../wear_shape.dart';
import '../widgets/focus_list.dart';
import '../widgets/wear_metrics.dart';
import '../widgets/wear_row.dart';
import 'house_switcher_page.dart';
import 'set_up_again_page.dart';
import 'sign_out_page.dart';
import 'wear_settings_page.dart';

/// Who this watch is, what it is still carrying, and the ways out.
///
/// Every entry is a row of the same centred-focus list the other pages are
/// built from, and every row that asks a question opens a page rather than
/// answering it in place: a wrist has no room for a control whose current
/// value you must read before you can predict what tapping it does.
///
/// Identity is the exception and rides as a header — it is a label, not a
/// target, which is what a header already means here.
class AccountPage extends StatefulWidget {
  /// Only the page being looked at may steer from the crown.
  final bool active;

  const AccountPage({super.key, required this.active});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _scroll = ScrollController();
  final _listKey = GlobalKey<SnapFocusListState>();
  final _geometry = ValueNotifier(const FocusGeometry());

  /// A route pushed over this page must take the crown with it: the detent
  /// stream is broadcast and a covered list stays mounted, so without this one
  /// turn of the bezel scrolls both the page on top and this one underneath.
  var _covered = false;

  /// Where *Set up again* ended up in the element list, so the landing can
  /// reach it without the row order being written down twice.
  int? _setUpAgainIndex;

  /// Whether the wearer has already been carried there. Once, on arriving into
  /// the state — not on every rebuild, which would haul the list back under
  /// somebody scrolling away from it.
  var _landed = false;

  @override
  void initState() {
    super.initState();
    AuthService.instance.isUnauthorized.addListener(_onDegraded);
    SyncManager.instance.pendingCount.addListener(_onChanged);
    WearMirrorClient.instance.addListener(_onChanged);
    WearScope.instance.addListener(_onChanged);
    _scheduleLanding();
  }

  @override
  void dispose() {
    AuthService.instance.isUnauthorized.removeListener(_onDegraded);
    SyncManager.instance.pendingCount.removeListener(_onChanged);
    WearMirrorClient.instance.removeListener(_onChanged);
    WearScope.instance.removeListener(_onChanged);
    _scroll.dispose();
    _geometry.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onDegraded() {
    if (!mounted) return;
    setState(() {});
    _scheduleLanding();
  }

  bool get _degraded => AuthService.instance.isUnauthorized.value;

  /// The degraded rail line is a signpost, and a signpost has to arrive at what
  /// it points at. A wearer who followed one lands on *Set up again* rather
  /// than one scroll above it.
  void _scheduleLanding() {
    if (!_degraded) {
      _landed = false;
      return;
    }
    if (_landed) return;
    _landed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = _setUpAgainIndex;
      if (mounted && index != null) _listKey.currentState?.centreOn(index);
    });
  }

  Future<void> _push(Widget page) async {
    setState(() => _covered = true);
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
    // The page behind may have changed what a row says about itself.
    if (mounted) setState(() => _covered = false);
  }

  /// The checklists page's rule, unchanged: a card that is not on the centre
  /// line scrolls there and nothing opens, so a mis-aim costs a scroll rather
  /// than a page.
  ///
  /// The distance is checked as well as the index, because this page opens on
  /// a header. Identity cannot be landed on, which leaves the household row
  /// the *nearest* snappable element while it sits a full row below the line —
  /// and a rule that trusted the index alone would fire on a row the wearer
  /// can see is not the one in charge.
  void _tap(int index, VoidCallback action) {
    final geometry = _geometry.value;
    if (index != geometry.centredIndex ||
        geometry.centredDistance > WearMetrics.itemExtent / 2) {
      _listKey.currentState?.centreOn(index);
      return;
    }
    action();
  }

  // -- The list --------------------------------------------------------------

  List<FocusElement> _elements() {
    final scheme = Theme.of(context).colorScheme;
    final elements = <FocusElement>[];
    _setUpAgainIndex = null;

    void header(double extent, Widget child) => elements.add(
      FocusElement(
        extent: extent,
        snappable: false,
        isHeader: true,
        builder: (context, _) => child,
      ),
    );

    void row({
      required IconData icon,
      Color tint = Colors.white70,
      required String label,
      String? Function()? value,
      bool warning = false,
      VoidCallback? onTap,
    }) {
      // Captured as the row is added, so the order lives in one place.
      final index = elements.length;
      elements.add(
        FocusElement(
          extent: WearMetrics.itemExtent,
          builder: (context, d) => Padding(
            padding: const EdgeInsetsDirectional.only(
              bottom: WearMetrics.cardGap,
            ),
            child: WearRow(
              icon: icon,
              tint: tint,
              label: label,
              value: value?.call(),
              warning: warning,
              distance: d,
              onTap: onTap == null ? null : () => _tap(index, onTap),
            ),
          ),
        ),
      );
    }

    header(_identityExtent, _Identity(credentials: _credentials));
    header(_syncExtent, _SyncStatus(queued: _queued, captured: _capturedAt));

    // Beside the identity it concerns, and above everything the wearer might
    // otherwise have come here to do.
    if (_degraded) {
      header(WearMetrics.headerExtent, const _DegradedNote());
      _setUpAgainIndex = elements.length;
      row(
        icon: Icons.lock_outline,
        label: m.wear.setUpAgain,
        onTap: () => unawaited(_push(const SetUpAgainPage())),
      );
    }

    row(
      icon: Icons.home_outlined,
      tint: scheme.primary,
      label: m.wear.house,
      value: () => _houseName,
      onTap: () => unawaited(_push(const HouseSwitcherPage())),
    );

    row(
      icon: Icons.tune,
      label: m.wear.settings,
      onTap: () => unawaited(_push(const WearSettingsPage())),
    );

    row(
      icon: Icons.logout,
      label: m.common.logout,
      warning: true,
      onTap: () => unawaited(_push(const SignOutPage())),
    );

    return elements;
  }

  /// Read here and handed down, never reached for inside the widget that draws
  /// them. A header that took none of them could be `const`, and a `const`
  /// widget is one canonical instance — so the parent's rebuild would find an
  /// identical child, skip its subtree, and the page would answer with whatever
  /// was true when it opened. The listeners above are what make these change;
  /// passing them is what makes that visible.
  NextcloudCredentials? get _credentials => AuthService.instance.credentials;

  int get _queued => SyncManager.instance.pendingCount.value;

  DateTime? get _capturedAt => WearMirrorClient.instance.capturedAt;

  String? get _houseName {
    final id = WearScope.instance.houseId;
    if (id == null) return null;
    for (final house in HouseService.instance.getCached() ?? const []) {
      if (house.id == id) return house.name;
    }
    return null;
  }

  /// Two lines and the space above them — more than a group header costs and
  /// less than a row, because identity is read once and never aimed at.
  static const double _identityExtent = 62;

  /// One line, under the identity it reports on.
  static const double _syncExtent = 20;

  @override
  Widget build(BuildContext context) {
    return SnapFocusList(
      key: _listKey,
      controller: _scroll,
      itemExtent: WearMetrics.itemExtent,
      falloffRows: WearMetrics.falloffRows,
      rotaryActive: widget.active && !_covered,
      geometry: _geometry,
      elements: _elements(),
    );
  }
}

/// Which account, and on which server. The wearer typed neither — the
/// credential is the phone's — so this is the one place the watch says out
/// loud whose household it is showing.
class _Identity extends StatelessWidget {
  final NextcloudCredentials? credentials;

  const _Identity({required this.credentials});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = credentials?.loginName ?? '';
    final server = _host(credentials?.serverUrl);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person, size: 18, color: scheme.primary),
        const SizedBox(height: 2),
        Text(
          name.isEmpty ? m.wear.notSignedIn : m.wear.signedInAs(name),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          textDirection: detectTextDirection(name),
          style: const TextStyle(
            fontSize: 12,
            height: 1.1,
            color: Colors.white,
          ),
        ),
        if (server != null)
          Text(
            server,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            textDirection: detectTextDirection(server),
            style: const TextStyle(
              fontSize: 10,
              height: 1.2,
              color: Colors.white38,
            ),
          ),
      ],
    );
  }
}

/// Whether the wearer's own work is safe, and how lately the phone pushed.
///
/// A label rather than a card, and under the identity rather than among the
/// rows: it answers a question instead of offering an action, and a tile among
/// tiles reads as one more thing to tap. Colour carries the state, so the
/// answer arrives before the words do.
///
/// The mirror half is absent when nothing has ever landed. A watch with no link
/// has no snapshot to be late, and "never synced" would name a fault the design
/// does not have — a standalone or F-Droid watch reads everything for itself
/// and is exactly as correct.
class _SyncStatus extends StatelessWidget {
  final int queued;
  final DateTime? captured;

  const _SyncStatus({required this.queued, required this.captured});

  static const _safe = Color(0xFF7FB77E);
  static const _waiting = Color(0xFFE0C07A);

  @override
  Widget build(BuildContext context) {
    final captured = this.captured;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              queued > 0 ? m.wear.queued(queued) : m.wear.allSaved,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.1,
                fontWeight: FontWeight.w600,
                color: queued > 0 ? _waiting : _safe,
              ),
            ),
          ),
          if (captured != null)
            Flexible(
              child: Text(
                ' · ${m.wear.syncedAgo(_ago(captured))}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  color: Colors.white38,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Why the row under this one is here. `common.sessionExpiredBody` is
/// phone-length prose — six lines at this size, on a page that also has to
/// carry identity, the house, sync and the way out.
class _DegradedNote extends StatelessWidget {
  const _DegradedNote();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.symmetric(
      horizontal: WearShape.isRound ? 24 : 12,
    ),
    child: Text(
      m.wear.sessionExpiredShort,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 10, height: 1.15, color: wearNoticeInk),
    ),
  );
}

/// Coarse, and short enough to sit at the end of a row beside the queue.
/// `relativeTime` is day-granular, which cannot say the thing that matters
/// here: whether the phone is pushing *now*.
String _ago(DateTime when) {
  final diff = DateTime.now().difference(when);
  if (diff.inMinutes < 1) return m.wear.agoJustNow;
  if (diff.inMinutes < 60) return m.wear.agoMinutes(diff.inMinutes);
  if (diff.inHours < 24) return m.wear.agoHours(diff.inHours);
  return m.wear.agoDays(diff.inDays);
}

String? _host(String? url) {
  if (url == null || url.isEmpty) return null;
  final host = Uri.tryParse(url)?.host;
  return host == null || host.isEmpty ? url : host;
}
