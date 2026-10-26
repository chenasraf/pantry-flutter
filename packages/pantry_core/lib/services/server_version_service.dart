import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/cache_store.dart';
import 'package:pantry_core/services/http_pool.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/utils/version.dart';

/// Owns the Nextcloud and Pantry version state.
///
/// Reads `/ocs/v2.php/cloud/capabilities` (public; can be probed pre-login
/// with `fetch(serverUrl: ...)`) and takes the Pantry version from
/// `capabilities.pantry.version`:
///
/// ```json
/// "pantry": {
///   "version": { "major": 0, "minor": 16, "micro": 0,
///                "string": "0.16.0", "array": [0, 16, 0] }
/// }
/// ```
///
/// Pantry releases before 0.16.0 don't register the capability. For those the
/// version is bounded by runtime probes — each probe's response discriminates
/// "route exists" vs "missing" for a feature in [_featureIntroduced], and
/// [isServerPantryVersion] answers from the resulting bounds.
class ServerVersionService {
  ServerVersionService._();
  static final ServerVersionService instance = ServerVersionService._();

  /// Probed feature → Pantry version that introduced it. Bounds the server
  /// version when the capability isn't reported.
  static const Map<String, String> _featureIntroduced = {
    'category-sort': '0.15.0',
    'item-authors': '0.15.0',
  };

  /// Feature → probe to run when the server reports no version. The probe
  /// must be a no-op for both ancient and current backends; it is sent on
  /// every login.
  static final Map<String, _FeatureProbe> _featureProbes = {
    'category-sort': const _FeatureProbe(
      path: '/houses/0/categories/reorder',
      body: {'order': []},
    ),
  };

  Version? _serverVersion;
  Version? get serverVersion => _serverVersion;

  Version? _pantryVersion;
  Version? get pantryVersion => _pantryVersion;

  Map<String, dynamic>? _themingCaps;

  /// Raw `theming` sub-object from the OCS capabilities response. When
  /// authenticated, the user-facing fields (`primaryColor`, `color`, ...)
  /// reflect the user's effective theme — personal accent if set, server
  /// default otherwise. Consumed by `ThemingService` on NC ≥ 34, where the
  /// legacy `/apps/theming/manifest/core` endpoint 500s.
  Map<String, dynamic>? get themingCaps => _themingCaps;

  bool _webPush = false;

  /// The Notifications app accepts web push subscriptions from app-password
  /// clients. An administrator toggle, so it can come and go on one server.
  bool get supportsWebPush => _webPush;

  /// Probe results, keyed by names in [_featureIntroduced].
  final Map<String, bool> _features = {};

  /// On-disk snapshot of the last successful capabilities fetch. Rehydrated by
  /// [loadCached] before the first frame so cold offline launches gate UI on
  /// the last-known version instead of having every [isServerPantryVersion]
  /// fail closed until the network call lands.
  final CacheStore _cache = CacheStore('capabilities_cache.json');

  /// Rehydrate version + probe + theming state from the on-disk snapshot of
  /// the previous successful [fetch]. Safe to call before login (no-op if the
  /// cache file is absent). Callers should still invoke [fetch] afterwards in
  /// the background to refresh against the live server.
  Future<void> loadCached() async {
    await _cache.load();
    _serverVersion = Version.tryParse(_cache.get<String>('serverVersion'));
    _pantryVersion = Version.tryParse(_cache.get<String>('pantryVersion'));
    final feats = _cache.getObject('features');
    if (feats != null) {
      for (final entry in feats.entries) {
        final v = entry.value;
        if (v is bool && _featureIntroduced.containsKey(entry.key)) {
          _features[entry.key] = v;
        }
      }
    }
    _themingCaps = _cache.getObject('themingCaps');
    _webPush = _cache.get<bool>('webPush') ?? false;
  }

  void _persist() {
    _cache.set<String?>('serverVersion', _serverVersion?.toString());
    _cache.set<String?>('pantryVersion', _pantryVersion?.toString());
    _cache.set<Map<String, dynamic>>(
      'features',
      Map<String, dynamic>.from(_features),
    );
    _cache.set<Map<String, dynamic>?>('themingCaps', _themingCaps);
    _cache.set<bool>('webPush', _webPush);
  }

  /// Reads `/ocs/v2.php/cloud/capabilities` and refreshes the version state.
  /// With [serverUrl], runs unauthenticated against a prospective server
  /// (onboarding); without it, uses the logged-in session.
  ///
  /// Feature probes run only when the user is authenticated AND the server
  /// reported no Pantry version.
  Future<void> fetch({String? serverUrl}) async {
    final creds = AuthService.instance.credentials;
    final baseUrl = serverUrl ?? creds?.serverUrl;
    if (baseUrl == null) return;

    final headers = <String, String>{
      'Accept': 'application/json',
      'OCS-APIREQUEST': 'true',
    };
    if (serverUrl == null && creds != null) {
      headers.addAll(creds.basicAuthHeaders);
    }

    try {
      final uri = Uri.parse(
        '$baseUrl/ocs/v2.php/cloud/capabilities?format=json',
      );
      final response = await HttpPool.shared.client.get(uri, headers: headers);
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final payload = data['ocs']?['data'] as Map<String, dynamic>?;
      if (payload == null) return;

      _serverVersion = Version.tryParse(
        (payload['version'] as Map<String, dynamic>?)?['string'] as String?,
      );

      final caps = payload['capabilities'] as Map<String, dynamic>?;
      final pantryCaps = caps?['pantry'] as Map<String, dynamic>?;
      _parsePantryCapability(pantryCaps);
      _themingCaps = caps?['theming'] as Map<String, dynamic>?;
      final push = (caps?['notifications'] as Map<String, dynamic>?)?['push'];
      _webPush = push is List && push.contains('webpush');
    } catch (e) {
      debugPrint('[ServerVersionService] Failed to fetch capabilities: $e');
    }

    if (creds != null) {
      await _runMissingProbes();
      _persist();
    }
  }

  void _parsePantryCapability(Map<String, dynamic>? pantryCaps) {
    if (pantryCaps == null) return;

    final versionField = pantryCaps['version'];
    if (versionField is Map<String, dynamic>) {
      _pantryVersion = Version.tryParse(versionField['string'] as String?);
    } else if (versionField is String) {
      _pantryVersion = Version.tryParse(versionField);
    }
  }

  Future<void> _runMissingProbes() async {
    if (_pantryVersion != null) return;
    for (final entry in _featureProbes.entries) {
      if (_features.containsKey(entry.key)) continue;
      _features[entry.key] = await _probe(entry.value);
    }
  }

  /// Lazy probe surface: callers that already have a house pref response can
  /// pass it in instead of forcing an extra request. The presence of the
  /// `showAddedBy` key in the response is the discriminator for
  /// `item-authors` (added in Pantry 0.15). Calls are no-ops once the feature
  /// status is known, or when the server reports its Pantry version.
  void observeHousePrefs(Map<String, dynamic> prefs) {
    if (_pantryVersion != null) return;
    _features.putIfAbsent(
      'item-authors',
      () => prefs.containsKey('showAddedBy'),
    );
  }

  Future<bool> _probe(_FeatureProbe spec) async {
    try {
      final uri = ApiClient.instance.buildUri(spec.path);
      final response = await HttpPool.shared.client.post(
        uri,
        headers: {
          ...ApiClient.instance.authHeaders,
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(spec.body),
      );
      // 405 = NC matched a parent prefix but no handler for this subpath.
      // 404 = no matching prefix at all. Both mean the feature is missing.
      return response.statusCode != 405 && response.statusCode != 404;
    } catch (e) {
      debugPrint('[ServerVersionService] probe ${spec.path} failed: $e');
      return false;
    }
  }

  void clear() {
    _serverVersion = null;
    _pantryVersion = null;
    _themingCaps = null;
    _webPush = false;
    _features.clear();
    unawaited(_cache.clear());
  }

  /// Compare against the Nextcloud server version, e.g.
  /// `isServerVersion('>=', '34.0.0')`. Returns `false` if unknown.
  bool isServerVersion(String op, String version) =>
      _serverVersion?.satisfies(op, Version.parse(version)) ?? false;

  /// Compare against the Pantry server-app version. When the server publishes
  /// its version under `capabilities.pantry.version`, that's used directly.
  /// Otherwise the answer is inferred from feature-probe results: each known
  /// feature establishes a lower or upper bound on the server version, and
  /// the comparison only returns `true` when those bounds prove the claim.
  /// Fails closed when the bounds are inconclusive.
  ///
  /// With the debug force-all-features pref on, the server is treated as
  /// newer than any [version], so every [ServerFeature] gate opens.
  bool isServerPantryVersion(String op, String version) {
    if (PrefsService.instance.devForceAllFeatures) {
      return op == '>=' || op == '>' || op == '!=';
    }
    return comparePantryVersion(
      op: op,
      target: Version.parse(version),
      known: _pantryVersion,
      features: _features,
      featureIntroduced: _featureIntroduced,
    );
  }

  @visibleForTesting
  void debugSeed({
    Version? pantryVersion,
    Map<String, bool> features = const {},
  }) {
    _pantryVersion = pantryVersion;
    _features
      ..clear()
      ..addAll(features);
  }
}

class _FeatureProbe {
  final String path;
  final Map<String, dynamic> body;
  const _FeatureProbe({required this.path, required this.body});
}

/// Pure inference used by [ServerVersionService.isServerPantryVersion]. Exposed
/// for tests; production callers should use the service.
@visibleForTesting
bool comparePantryVersion({
  required String op,
  required Version target,
  required Version? known,
  required Map<String, bool> features,
  required Map<String, String> featureIntroduced,
}) {
  if (known != null) {
    return known.satisfies(op, target);
  }

  // Each supported feature proves `server >= introducedIn(feature)`; each
  // unsupported feature proves `server < introducedIn(feature)`. The tightest
  // bound wins.
  Version? lowerBound;
  Version? upperBound;
  features.forEach((name, supported) {
    final introducedString = featureIntroduced[name];
    if (introducedString == null) return;
    final introduced = Version.parse(introducedString);
    if (supported) {
      if (lowerBound == null || introduced.compareTo(lowerBound!) > 0) {
        lowerBound = introduced;
      }
    } else {
      if (upperBound == null || introduced.compareTo(upperBound!) < 0) {
        upperBound = introduced;
      }
    }
  });

  switch (op) {
    case '>=':
      return lowerBound != null && lowerBound!.compareTo(target) >= 0;
    case '>':
      return lowerBound != null && lowerBound!.compareTo(target) > 0;
    case '<':
    case '<=':
      // Upper bound is strict (`server < introduced(feature)`), so it also
      // proves `server <= target` whenever `upperBound <= target`.
      return upperBound != null && upperBound!.compareTo(target) <= 0;
    case '==':
    case '=':
    case '!=':
      // Bounds alone never prove exact equality.
      return false;
    default:
      return false;
  }
}

/// Top-level convenience wrapping [ServerVersionService.instance].
bool isServerVersion(String op, String version) =>
    ServerVersionService.instance.isServerVersion(op, version);

bool isServerPantryVersion(String op, String version) =>
    ServerVersionService.instance.isServerPantryVersion(op, version);

/// Server-dependent Pantry features, each gated on the first Pantry release
/// that shipped it.
abstract final class ServerFeature {
  static bool _since(String version) => isServerPantryVersion('>=', version);

  // Pantry servers before 0.16.0 publish no version. These two are detected by
  // probes, which bound the version to at least 0.15.0.
  static bool get categorySort => _since('0.15.0');
  static bool get itemAuthors => _since('0.15.0');

  static bool get checklistColor => _since('0.16.0');
  static bool get notePinning => _since('0.16.0');

  static bool get checklistSort => _since('0.17.0');
  static bool get checklistTrash => _since('0.17.0');
  static bool get noteTrash => _since('0.17.0');
  static bool get photoTrash => _since('0.17.0');

  static bool get checklistAllView => _since('0.18.0');
  static bool get copyItems => _since('0.18.0');

  static bool get reuseExistingItems => _since('0.19.0');

  static bool get batchOperations => _since('0.20.0');
  static bool get roles => _since('0.20.0');
  static bool get shareUsers => _since('0.20.0');

  static bool get itemArchive => _since('0.21.0');

  static bool get stores => _since('0.22.0');

  static bool get itemPrice => _since('0.24.0');

  static bool get shopping => _since('0.25.0');
  static bool get storeSort => _since('0.25.0');

  static bool get customOrderWithinGroups => _since('0.27.0');
  static bool get uncheckAll => _since('0.27.0');

  static bool get labels => _since('0.28.0');
  static bool get labelSort => _since('0.28.0');
  static bool get labelLists => _since('0.28.0');
  static bool get categoryLists => _since('0.28.0');
  static bool get itemPricePerStore => _since('0.28.0');

  static bool get checklistArchive => _since('0.29.0');
  static bool get checklistTrashOpen => _since('0.29.0');

  static bool get customFields => _since('0.30.0');
  static bool get prefSuggestArchivedItems => _since('0.30.0');

  static bool get listDefaultRecurrence => _since('0.31.0');

  static bool get shoppingJoinSession => _since('0.33.0');
  static bool get shoppingItemSelection => _since('0.33.0');
  static bool get storeCategoryOrder => _since('0.33.0');

  static bool get noteFileSync => _since('0.34.0');

  static bool get checklistDuplicate => _since('0.35.0');
  static bool get checklistCompletionTime => _since('0.35.0');
  static bool get prefBarcodeFill => _since('0.35.0');

  static bool get listItemDefaults => _since('0.36.0');

  static bool get listItemSort => _since('0.37.0');
  static bool get shoppingHistoryDelete => _since('0.37.0');
}
