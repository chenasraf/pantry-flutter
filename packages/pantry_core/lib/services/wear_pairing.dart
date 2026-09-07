import 'package:pantry_core/services/auth_service.dart';

/// The credential handoff's wire contract, held in core because both halves
/// speak it: the watch asks, the phone answers.
///
/// Paths are stable across releases — two app versions on a phone and a watch
/// that update on their own schedules have to agree on them — so they are
/// spelled out here rather than composed at the call site.
class WearPairing {
  WearPairing._();

  /// Watch → phone. Carries nothing: the phone reads which watch is asking
  /// from the link's own node id, and there is nothing else to say.
  static const requestPath = '/pairing/request';

  /// Phone → watch, carrying a [WearPairingGrant].
  static const grantPath = '/pairing/grant';

  /// Phone → watch, carrying a [WearPairingRefusal]. Only sent for a condition
  /// the watch cannot detect on its own.
  static const refusalPath = '/pairing/refusal';

  /// Phone → watch, carrying a [WearPairingState]. Published rather than
  /// sent: a message reaches nothing on a watch whose app is not running,
  /// which is a watch almost all of the time.
  static const statePath = '/pairing/state';
}

/// Which watch a phone has signed in — the pairing itself, as absolute state.
///
/// The phone publishes this rather than sending an unpair, because a watch
/// away across both a grant and an unpair would learn neither. Absence carries
/// no information: a watch that reads nothing here was signed in by some other
/// route, or by a phone too old to publish, and is left alone. So a phone with
/// nobody signed in publishes an empty pairing rather than deleting the item.
class WearPairingState {
  /// The granted node, or null for a phone that has signed nobody in.
  final String? nodeId;

  const WearPairingState({this.nodeId});

  Map<String, dynamic> toJson() => {'nodeId': nodeId};

  static WearPairingState fromJson(Map<String, dynamic> json) =>
      WearPairingState(
        nodeId: switch (json['nodeId']) {
          final String id when id.isNotEmpty => id,
          _ => null,
        },
      );
}

/// Why a phone answered a pairing request with nothing to hand over.
enum WearPairingRefusal {
  /// The phone holds no credential of its own. The one failure the watch has
  /// no way to infer, and the likeliest one: retrying cannot fix it, so the
  /// watch says what will.
  signedOut('signedOut');

  const WearPairingRefusal(this.wire);

  final String wire;

  static WearPairingRefusal? fromWire(String? wire) {
    for (final reason in values) {
      if (reason.wire == wire) return reason;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {'reason': wire};

  static WearPairingRefusal? fromJson(Map<String, dynamic> json) =>
      fromWire(json['reason'] as String?);
}

/// Everything a watch needs before it can talk to the server, and nothing it
/// can work out for itself.
///
/// The house data that follows is not here: it rides the mirror, which the
/// watch pulls once it has a scope to report. What this carries is the part
/// that has no other source — a credential the watch cannot type, the pins it
/// cannot be asked to judge, and the scope it has no way to guess.
class WearPairingGrant {
  final NextcloudCredentials credentials;

  /// `host[:port]` → accepted SHA-256 fingerprints, as
  /// `CertTrustService.export` produces them.
  final Map<String, List<String>> certPins;

  /// The phone's current house and list, seeded once. Authority over scope
  /// passes to the watch from here on, so these are a starting point rather
  /// than a value the phone keeps writing.
  final int? houseId;
  final int? listId;

  /// The only pref that crosses, so an item row on the wrist shows the chips
  /// the wearer already chose on the phone rather than the full set.
  final Set<String> hiddenItemChips;

  const WearPairingGrant({
    required this.credentials,
    required this.certPins,
    this.houseId,
    this.listId,
    this.hiddenItemChips = const {},
  });

  Map<String, dynamic> toJson() => {
    'credentials': credentials.toJson(),
    'certPins': {for (final e in certPins.entries) e.key: e.value},
    'houseId': houseId,
    'listId': listId,
    'hiddenItemChips': hiddenItemChips.toList(),
  };

  /// Null for a payload this build cannot read, which a truncated transfer or
  /// a newer sender both produce. The caller shows the setup screen again
  /// rather than half-applying one.
  static WearPairingGrant? fromJson(Map<String, dynamic> json) {
    final rawCredentials = json['credentials'];
    if (rawCredentials is! Map) return null;
    final NextcloudCredentials credentials;
    try {
      credentials = NextcloudCredentials.fromJson(
        Map<String, dynamic>.from(rawCredentials),
      );
    } catch (_) {
      return null;
    }
    if (credentials.serverUrl.isEmpty || credentials.appPassword.isEmpty) {
      return null;
    }
    final rawPins = json['certPins'];
    return WearPairingGrant(
      credentials: credentials,
      certPins: rawPins is! Map
          ? const {}
          : {
              for (final entry in rawPins.entries)
                if (entry.value is List)
                  '${entry.key}': [
                    for (final fingerprint in entry.value as List)
                      '$fingerprint',
                  ],
            },
      houseId: json['houseId'] as int?,
      listId: json['listId'] as int?,
      hiddenItemChips: switch (json['hiddenItemChips']) {
        final List raw => {for (final chip in raw) '$chip'},
        _ => const {},
      },
    );
  }
}
