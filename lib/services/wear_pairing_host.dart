import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/cache_store.dart';
import 'package:pantry_core/services/cert_trust_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/wear_link_service.dart';
import 'package:pantry_core/services/wear_pairing.dart';

import 'wear_mirror_host.dart';

/// A watch asking to be signed in, waiting on a human.
class WearPairingRequest {
  final String nodeId;

  /// What the watch calls itself, as the link reports it. The confirmation
  /// names it, since a household can have more than one paired watch and the
  /// wearer of the other one is who the confirmation defends against.
  final String nodeName;

  const WearPairingRequest({required this.nodeId, required this.nodeName});
}

/// The phone's half of the credential handoff.
///
/// It listens for as long as the process lives rather than only while the
/// pairing route is open, because a request reaching a phone with no listener
/// is delivered to nothing — and the one answer worth giving while signed out
/// is the refusal that stops the watch retrying against a phone that can never
/// succeed.
///
/// What it will not do is hand the credential over on its own. Play services
/// proves the requester is our app on a watch already paired to this phone,
/// which does not prove it is on the right wrist; the confirmation is what
/// covers a household watch worn by someone else.
class WearPairingHost {
  WearPairingHost._();

  static final WearPairingHost instance = WearPairingHost._();

  final _link = WearLinkService.instance;

  /// Which watch was granted, and when. Its own file rather than a pref: it
  /// describes a peer rather than a preference, and a sign-out clears the
  /// prefs while a pairing outlives one.
  final _store = CacheStore('wear_pairing.json');

  static const _nodeIdKey = 'nodeId';
  static const _nodeNameKey = 'nodeName';
  static const _pairedAtKey = 'pairedAt';

  StreamSubscription<WearLinkMessage>? _messages;

  /// The request awaiting an answer, or null. The pairing route watches this;
  /// a request arriving while the route is closed simply waits here, and the
  /// watch's next re-send finds it already pending.
  final pending = ValueNotifier<WearPairingRequest?>(null);

  /// The watch this phone has signed in, as far as it knows. Rebuilt from the
  /// store on [init] so the settings row can name it on first frame.
  final paired = ValueNotifier<WearPairingRequest?>(null);

  /// Watches whose request was refused. The watch goes on re-sending — it has
  /// no way to hear a denial and nothing useful to do with one — so without
  /// this the prompt would reappear seconds after being dismissed. Not
  /// persisted: it describes this sitting, not this pairing.
  final _denied = <String>{};

  DateTime? get pairedAt {
    final stamp = _store.get<int>(_pairedAtKey);
    return stamp == null ? null : DateTime.fromMillisecondsSinceEpoch(stamp);
  }

  Future<void> init() async {
    if (_messages != null) return;
    if (!await _link.isAvailable()) return;
    // Before the first write: the store rewrites its whole file per mutation,
    // so granting against an unloaded one would erase what it held.
    await _store.load();
    final nodeId = _store.get<String>(_nodeIdKey);
    if (nodeId != null) {
      paired.value = WearPairingRequest(
        nodeId: nodeId,
        nodeName: _store.get<String>(_nodeNameKey) ?? '',
      );
      WearMirrorHost.instance.pairedNode = nodeId;
      // A pairing granted before the phone published any heals itself here,
      // and an identical item is a no-op on the wire. Nothing is published
      // when the store is empty: a phone that has paired nobody has no
      // statement to make, and "nobody" would be one.
      await _publish(nodeId);
    }
    _messages = _link.messages.listen(_onMessage);
  }

  Future<void> dispose() async {
    await _messages?.cancel();
    _messages = null;
    pending.value = null;
  }

  void _onMessage(WearLinkMessage message) {
    if (message.path != WearPairing.requestPath) return;
    final nodeId = message.nodeId;
    if (nodeId == null) return;
    // Signed out is the one state worth answering unprompted: no confirmation
    // could produce a credential, so raising one would only ask the user to
    // approve a transfer that cannot happen.
    if (!AuthService.instance.isLoggedIn) {
      unawaited(
        _link.send(
          WearPairing.refusalPath,
          WearPairingRefusal.signedOut.toJson(),
          nodeId: nodeId,
        ),
      );
      return;
    }
    unawaited(_raise(nodeId));
  }

  Future<void> _raise(String nodeId) async {
    if (_denied.contains(nodeId)) return;
    final current = pending.value;
    if (current != null && current.nodeId == nodeId) return;
    final nodes = await _link.nodes();
    final name = nodes
        .cast<WearLinkNode?>()
        .firstWhere((node) => node!.id == nodeId, orElse: () => null)
        ?.name;
    pending.value = WearPairingRequest(nodeId: nodeId, nodeName: name ?? '');
  }

  /// Refuse the request. Nothing is sent back: there is no state the watch
  /// could usefully enter on hearing it, and the three it can already reach
  /// are the ones it can act on.
  void deny() {
    final request = pending.value;
    if (request != null) _denied.add(request.nodeId);
    pending.value = null;
  }

  /// Opening the pairing screen is the deliberate act of reconsidering, so a
  /// refusal made earlier stops suppressing the prompt.
  void reconsider() => _denied.clear();

  /// Hand [request]'s watch everything it cannot obtain for itself, then push
  /// the house data behind it.
  ///
  /// The caller holds the phone open across this: both carriers need the
  /// process alive with the link's listeners attached, and there is nothing
  /// here that survives the app being backgrounded mid-transfer.
  Future<bool> grant(WearPairingRequest request) async {
    final credentials = AuthService.instance.credentials;
    if (credentials == null) return false;
    final grant = WearPairingGrant(
      credentials: credentials,
      certPins: CertTrustService.instance.export(),
      houseId: PrefsService.instance.lastHouseId,
      listId: ChecklistService.instance.selectedListId,
      hiddenItemChips: PrefsService.instance.hiddenItemChips,
    );
    final delivered = await _link.send(
      WearPairing.grantPath,
      grant.toJson(),
      nodeId: request.nodeId,
    );
    if (!delivered) return false;

    pending.value = null;
    paired.value = request;
    _store.set(_nodeIdKey, request.nodeId);
    _store.set(_nodeNameKey, request.nodeName);
    _store.set(_pairedAtKey, DateTime.now().millisecondsSinceEpoch);
    await _publish(request.nodeId);

    // The seed is the mirror's first write, not a payload of its own. The
    // watch reports its scope once the grant lands and the mirror answers
    // that, so all this does is make sure the host is listening for it.
    WearMirrorHost.instance.pairedNode = request.nodeId;
    await WearMirrorHost.instance.init();
    return true;
  }

  /// Forget the paired watch, and say so where a sleeping watch will find it.
  ///
  /// Nothing is revoked: the app password is the phone's own, and this device
  /// is not the one leaving.
  Future<void> unpair() async {
    // Only a phone with something to withdraw says so. "Nobody" is a
    // statement, and one made by a phone that paired nobody would forget a
    // watch signed in by some other route.
    if (paired.value == null) return;
    // An empty pairing rather than a deletion — the watch reads absence as
    // "this phone has never said", which is what leaves a QR-signed-in or
    // F-Droid watch alone.
    await _publish(null);
    WearMirrorHost.instance.pairedNode = null;
    paired.value = null;
    pending.value = null;
    // Unpairing is at least as deliberate an act about this watch as opening
    // the pairing screen, so a refusal made earlier stops suppressing it here
    // too. Without this, setting the same watch up again raises nothing until
    // the screen happens to be reopened — and the watch, which re-sends every
    // five seconds and has no state to enter on being ignored, simply waits.
    reconsider();
    await _store.clear();
  }

  Future<void> _publish(String? nodeId) => _link.publish(
    WearPairing.statePath,
    WearPairingState(nodeId: nodeId).toJson(),
  );
}
