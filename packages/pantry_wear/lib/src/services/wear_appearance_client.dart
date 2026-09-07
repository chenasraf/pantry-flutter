import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/locale_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/theming_service.dart';
import 'package:pantry_core/services/wear_appearance.dart';
import 'package:pantry_core/services/wear_link_service.dart';

import 'wear_tile_service.dart';

/// The watch's half of the appearance publication: it reads what the phone
/// says about how it draws, and holds it as a default.
///
/// Every landed field is a default and nothing more. An explicit choice on the
/// wrist sits above it in the same resolvers the phone uses, so a wearer who
/// picks a language keeps it whatever their phone goes on publishing — which
/// is what keeps this a published default rather than a synced preference.
///
/// A watch nobody publishes to reads nothing here and is left entirely alone:
/// absence carries no information, so the QR-signed-in watch and the one
/// paired to a build with no Data Layer need no case of their own.
class WearAppearanceClient {
  WearAppearanceClient._();

  static final WearAppearanceClient instance = WearAppearanceClient._();

  final _link = WearLinkService.instance;

  StreamSubscription<WearLinkMessage>? _messages;

  var _started = false;

  /// The accent as the Tile was last told it. The Tile is drawn by the system
  /// with no engine running, so it holds its own copy and would go on drawing
  /// a stale one until a list happened to be renamed.
  Color? _accent;

  /// Read what is already published, then follow it.
  ///
  /// The read is unawaited by its caller and never gates the first frame: the
  /// landed values are persisted, so the cache paints frame one in the right
  /// language and a changed one applies when it arrives. A channel round trip
  /// costs 311 ms, which is the whole of a beat in the wrong accent against
  /// that on every single cold start.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    // Attached before the link is asked about, and whatever it answers: an
    // F-Droid watch has no publication to follow and still has a Tile and a
    // wrist control over the accent.
    _accent = ThemingService.instance.effectiveColor;
    ThemingService.instance.addListener(_onTheming);
    if (!await _link.isAvailable()) return;
    _messages = _link.messages.listen(_onMessage);
    // A `DataItem` reports a *change*, and the one that matters landed while
    // this watch was asleep — which is most of them.
    for (final item in await _link.dataItems(WearAppearance.path)) {
      await _land(item.data);
    }
  }

  /// Read the publication again, now that this watch may take it on.
  ///
  /// The pairing hands over credentials by message and states the appearance
  /// by `DataItem`, on two carriers with no ordering between them — so the
  /// statement can arrive at a watch that is still signed out, where [_land]
  /// refuses it. Nothing would read it again until the next launch, which is a
  /// wearer signing in and finding the wrong language.
  ///
  /// Cheap to call whenever a session begins: the item is already on the
  /// device, and landing what is already in force is a no-op.
  Future<void> refresh() async {
    if (!_started) return;
    if (!await _link.isAvailable()) return;
    for (final item in await _link.dataItems(WearAppearance.path)) {
      await _land(item.data);
    }
  }

  /// One rule for both triggers: whatever moved the accent — a phone's
  /// publication or the wearer's own opt-out — the Tile is told.
  void _onTheming() {
    final accent = ThemingService.instance.effectiveColor;
    if (accent == _accent) return;
    _accent = accent;
    unawaited(WearTileService.instance.republish());
  }

  /// Drop the phone's defaults, leaving the wearer's own choices standing.
  ///
  /// A watch that has forgotten its household has also forgotten which phone
  /// was speaking for it, and a language published by a phone this watch is no
  /// longer paired to is exactly the stale divergence the publication exists
  /// to close.
  Future<void> forget() async {
    await PrefsService.instance.setPhoneAppearance(
      locale: null,
      useServerThemeColor: null,
    );
    await ThemingService.instance.adoptPublishedColor(null);
    LocaleService.instance.apply();
  }

  Future<void> _onMessage(WearLinkMessage message) async {
    if (message.path != WearAppearance.path) return;
    await _land(message.data);
  }

  /// Take a statement on, and repaint whatever it changed.
  ///
  /// [LocaleService.apply] rather than `setLocale`: the wearer chose nothing
  /// here, so the revision is untouched and this is a rebuild rather than a
  /// reset. On the phone a teardown is cheap because a back button reaches
  /// anywhere in one tap; under a watch's edge-strip back gesture it would
  /// charge the wearer three drags to return to where they were standing.
  Future<void> _land(Map<String, dynamic> data) async {
    // A signed-out watch takes nothing from a phone. The publication is a
    // `DataItem` and outlives the session it was made for, so without this a
    // local sign-out is undone by the next launch: [start] re-reads the item
    // and lands the very accent and language the wearer just dropped. The
    // mirror carries the same guard, for the same reason.
    if (!AuthService.instance.isLoggedIn) return;
    final state = WearAppearanceState.fromJson(data);
    await PrefsService.instance.setPhoneAppearance(
      locale: state.locale,
      useServerThemeColor: state.useServerThemeColor,
    );
    await ThemingService.instance.adoptPublishedColor(state.themeColorHex);
    LocaleService.instance.apply();
  }

  /// Detach from the link and the theme so a test can start a second client
  /// against a different fake. Awaited: the link's stream is shared, and a
  /// subscription still tearing down would take the next test's events with it.
  @visibleForTesting
  Future<void> debugReset() async {
    await _messages?.cancel();
    _messages = null;
    if (_started) ThemingService.instance.removeListener(_onTheming);
    _started = false;
    _accent = null;
  }
}
