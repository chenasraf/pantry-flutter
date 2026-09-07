import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/cert_trust_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/wear_link_service.dart';
import 'package:pantry_core/services/wear_pairing.dart';

import '../services/wear_appearance_client.dart';
import '../services/wear_host_service.dart';
import '../services/wear_mirror_client.dart';
import '../wear_stores.dart';

/// Where the watch has got to in getting itself signed in.
enum WearSetupState {
  /// Asking the link whether it exists at all. Brief, and never returned to.
  checking,

  /// No Data Layer on this device — an F-Droid build, or a watch with no Play
  /// services. A dead end rather than a wait.
  unavailable,

  /// The link works and nothing is connected to it.
  noPhone,

  /// A phone is connected and the request is going out on a timer. Whether
  /// the phone app is installed, open, or merely unattended looks identical
  /// from here, so this state makes no promises about which.
  waiting,

  /// The phone answered that it holds no credential of its own. Retrying
  /// cannot fix it, so the loop stops here.
  phoneSignedOut,

  /// The credential landed and the house data behind it is on its way.
  syncing,

  /// Signed in, with something to show.
  ready,
}

/// The watch's half of the credential handoff.
///
/// The watch starts the flow because the watch is where the problem is
/// discovered — a wearer raises their wrist and finds the app signed out —
/// while the phone is the only device that can answer. It re-sends on a timer
/// rather than once, which is what makes the screen self-healing in every
/// ordering: whether the phone app was already open, opened from the button,
/// or opened from the launcher a minute later, the next re-send finds a live
/// listener.
class WearPairingClient extends ChangeNotifier {
  WearPairingClient._();

  static final WearPairingClient instance = WearPairingClient._();

  final _link = WearLinkService.instance;

  StreamSubscription<WearLinkMessage>? _messages;
  Timer? _retry;
  Timer? _seedDeadline;

  var _state = WearSetupState.checking;

  /// Whether the grant this round is waiting for is a first pairing, and so
  /// carries the seed, or a renewal of a credential the watch already had.
  var _seeding = true;

  WearSetupState get state => _state;

  /// Slow enough not to spend the radio on a screen that may be up for
  /// minutes, quick enough that a user walking to their phone and opening the
  /// app does not stand there wondering.
  static const _retryInterval = Duration(seconds: 5);

  /// How long the syncing state waits for the first snapshot before entering
  /// the app anyway. The mirror only ever accelerates — the watch can fetch
  /// everything here for itself now that it holds a credential — so a phone
  /// that goes quiet mid-transfer must not be able to strand the wearer on a
  /// spinner.
  static const _seedWait = Duration(seconds: 15);

  /// Listen to the link, and ask it for a session if this watch has none.
  ///
  /// The listening half runs whether or not the watch is signed in: unpair is
  /// a phone-side control, and a watch that only listened while signed out
  /// could never hear it.
  Future<void> start() async {
    if (!await _attach()) {
      _enter(WearSetupState.unavailable);
      return;
    }
    if (AuthService.instance.isLoggedIn) {
      _enter(WearSetupState.ready);
      return;
    }
    _seeding = true;
    await _tick();
    _retry ??= Timer.periodic(_retryInterval, (_) => unawaited(_tick()));
  }

  /// Ask the phone for a fresh credential while giving nothing up.
  ///
  /// The way out of a rejected credential cannot be [forget]: a 401 holds the
  /// queue rather than clearing it, and forgetting would destroy the unsent
  /// writes the wearer is renewing in order to send. Nothing local is dropped
  /// here — not the caches, not the queue, and not scope, which the phone
  /// seeds once at pairing and never overrides.
  Future<void> renew() async {
    if (!await _attach()) {
      _enter(WearSetupState.unavailable);
      return;
    }
    // A renewal can be asked for from a state the retry loop stopped in, and
    // the phone may since have signed back in.
    if (_state == WearSetupState.phoneSignedOut) {
      _enter(WearSetupState.checking);
    }
    _seeding = false;
    await _tick();
    _retry ??= Timer.periodic(_retryInterval, (_) => unawaited(_tick()));
  }

  /// Take on a session the watch signed itself into, with no phone involved.
  ///
  /// There is no grant here and so nothing to seed from: scope falls to the
  /// lowest-`sortOrder` list by the same rule that covers every other invalid
  /// scope, and the pins were accepted on this device rather than transferred.
  /// The stores are loaded here because a signed-out watch boots without them,
  /// and a snapshot or a queued write landing in an unloaded store replaces
  /// whatever the last session left in it.
  Future<void> adoptLocalSignIn() async {
    _stopAsking();
    await loadWearStores();
    _askForNotifications();
    _enter(WearSetupState.ready);
  }

  /// Ask for the notification grant, once, at the end of setting the watch up.
  ///
  /// It is the one moment the wearer is already attending to the watch with
  /// both hands and expecting to be asked something, and it is before any trip
  /// exists — where every other moment to ask is mid-shop. A refusal is not a
  /// setup failure: everything else on the watch works without it, and the
  /// settings page is where the answer can be seen and changed afterwards.
  void _askForNotifications() =>
      unawaited(WearHostService.instance.requestNotifications());

  /// Find out whether the phone still counts this watch as its own.
  ///
  /// Started from `main()` and never awaited: an unpaired watch draws its
  /// cached list for a beat before clearing, which is cheaper than spending a
  /// channel round trip on every cold start for a case most wearers never
  /// meet — and those names were readable at leisure at any point before now.
  Future<void> readPairing() async {
    if (!await _attach()) return;
    for (final item in await _link.dataItems(WearPairing.statePath)) {
      await _readState(item.data);
    }
  }

  @override
  void dispose() {
    _stopAsking();
    unawaited(_messages?.cancel());
    _messages = null;
    super.dispose();
  }

  /// Attach to the link, or report that there is none to attach to.
  Future<bool> _attach() async {
    if (_messages != null) return true;
    if (!await _link.isAvailable()) return false;
    _messages = _link.messages.listen(_onMessage);
    return true;
  }

  /// Drop the retry loop and the seed deadline, leaving the link subscription
  /// attached.
  void _stopAsking() {
    _retry?.cancel();
    _retry = null;
    _seedDeadline?.cancel();
    _seedDeadline = null;
  }

  /// One round of the loop: look for a phone, and ask the one that is there.
  ///
  /// Nodes are re-read every round rather than once, so a phone coming into
  /// range moves the screen off "connect your phone" without the wearer
  /// touching anything.
  Future<void> _tick() async {
    if (_state == WearSetupState.phoneSignedOut) return;
    final nodes = await _link.nodes();
    if (nodes.isEmpty) {
      _enter(WearSetupState.noPhone);
      return;
    }
    _enter(WearSetupState.waiting);
    await _link.send(WearPairing.requestPath, const {});
  }

  void _onMessage(WearLinkMessage message) {
    switch (message.path) {
      case WearPairing.grantPath:
        final grant = WearPairingGrant.fromJson(message.data);
        // A payload this build cannot read is one it must not half-apply: the
        // loop keeps running and the next re-send gets another answer.
        if (grant != null) unawaited(_accept(grant));
      case WearPairing.refusalPath:
        if (WearPairingRefusal.fromJson(message.data) ==
            WearPairingRefusal.signedOut) {
          _retry?.cancel();
          _retry = null;
          _enter(WearSetupState.phoneSignedOut);
        }
      case WearPairing.statePath:
        unawaited(_readState(message.data));
    }
  }

  /// Act on the pairing the phone published.
  ///
  /// Only a *present* item naming somebody else, or nobody, makes this watch
  /// forget. A watch signed in through the QR path, one whose phone is too old
  /// to publish and one with no Data Layer at all read nothing here and are
  /// all left alone — one rule rather than three exemptions.
  Future<void> _readState(Map<String, dynamic> data) async {
    if (!AuthService.instance.isLoggedIn) return;
    final local = await _link.localNode();
    // Nothing to compare against is not a statement that we were unpaired.
    if (local == null) return;
    if (WearPairingState.fromJson(data).nodeId == local.id) return;
    await forget();
  }

  /// Take on the session, then wait for the house data behind it.
  Future<void> _accept(WearPairingGrant grant) async {
    _retry?.cancel();
    _retry = null;

    // Pins first: they describe how to reach the server, and an HTTPS call
    // made before they land is one the watch has no way to answer for.
    await CertTrustService.instance.adopt(grant.certPins);
    await AuthService.instance.adoptCredentials(grant.credentials);

    // A renewal replaces the credential and nothing else. The stores are
    // already loaded and already hold what the wearer was reading, and the
    // seed below would overwrite the scope they have since chosen for
    // themselves. The rejection clears itself: the next request to succeed is
    // what disproves it.
    if (!_seeding) {
      _enter(WearSetupState.ready);
      return;
    }

    await PrefsService.instance.setHiddenItemChips(grant.hiddenItemChips);

    // Before the scope is written, and before a snapshot can land: both go
    // into stores that rewrite their whole file per mutation.
    await loadWearStores();

    final houseId = grant.houseId;
    if (houseId != null) await PrefsService.instance.setLastHouseId(houseId);
    // Seeded once and never overridden. From here the watch owns its scope,
    // including the meta list, which is a legal value rather than a mode.
    if (grant.listId != null) {
      ChecklistService.instance.selectedListId = grant.listId;
    }

    _enter(WearSetupState.syncing);

    // Reporting the scope is what asks for the seed: the phone mirrors what
    // the watch says it is showing, and the first of those snapshots is it.
    WearMirrorClient.instance.addListener(_onSnapshot);
    _seedDeadline = Timer(_seedWait, _finishSyncing);
    await WearMirrorClient.instance.start();
    await WearMirrorClient.instance.reportScope();
    await WearMirrorClient.instance.requestMirror();
  }

  void _onSnapshot() {
    if (WearMirrorClient.instance.landedAt == null) return;
    _finishSyncing();
  }

  void _finishSyncing() {
    if (_state != WearSetupState.syncing) return;
    _seedDeadline?.cancel();
    _seedDeadline = null;
    WearMirrorClient.instance.removeListener(_onSnapshot);
    _stopAsking();
    _askForNotifications();
    _enter(WearSetupState.ready);
  }

  /// Drop the session and everything it cached, without revoking: the app
  /// password is the phone's own and it is not the device leaving.
  ///
  /// The caches go because this is the deliberate act — a watch handed on or
  /// reset — rather than the 401 that must keep them readable. Household names
  /// left on a watch someone else now wears would be the same leak the
  /// pairing confirmation exists to prevent.
  Future<void> forget() async {
    _stopAsking();
    await AuthService.instance.logout(revoke: false);
    await clearWearStores();
    // Settings go with the account, wrist choices included. The caches are
    // cleared because this is the deliberate act — a watch handed on or reset
    // — and everything describing *how* this watch draws was chosen for that
    // same household: the language, the accent, what the crown steers, how
    // long a tap stays reversible, which chips a row shows. A watch set up
    // again, by anyone, starts where a new one does.
    await PrefsService.instance.clear();
    // The prefs are gone but the services that resolved from them are not:
    // the accent is held in memory by `ThemingService` and `m` still points at
    // the last language's messages, so both are re-derived here.
    await WearAppearanceClient.instance.forget();
    _state = WearSetupState.checking;
    notifyListeners();
    await start();
  }

  void _enter(WearSetupState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  /// Run one round of the retry loop now, rather than waiting out the timer.
  @visibleForTesting
  Future<void> debugTick() => _tick();

  /// Drop every timer and subscription so a test can start a second client
  /// against a different fake link. Awaited, because the link's stream is
  /// shared and a subscription still tearing down would take the next test's
  /// events with it.
  @visibleForTesting
  Future<void> debugReset() async {
    _stopAsking();
    await _messages?.cancel();
    _messages = null;
    WearMirrorClient.instance.removeListener(_onSnapshot);
    _state = WearSetupState.checking;
  }
}
