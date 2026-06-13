import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pantry/services/api_client.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/utils/version.dart';

/// Owns the Nextcloud and Pantry version state, plus the feature-support map.
///
/// Reads `/ocs/v2.php/cloud/capabilities` (public; can be probed pre-login
/// with `fetch(serverUrl: ...)`) and consumes the Pantry capability shape:
///
/// ```json
/// "pantry": {
///   "version": { "major": 0, "minor": 15, "micro": 0,
///                "string": "0.15.0", "array": [0, 15, 0] },
///   "features": [
///     "houses", "checklists", "categories", "category-sort",
///     "photos", "notes", "notifications", "item-images",
///     "recurring-items", "move-items", "one-off-items", "activity",
///     "soft-delete", "pref-tap-row-to-complete", "pref-category-spacing"
///   ]
/// }
/// ```
///
/// Feature names are kebab-case as exposed by the backend.
///
/// For Pantry installs that don't yet register the capability (everything
/// shipped before this rolls out), versions and features are inferred from
/// runtime probes — each gated feature has a probe request whose response
/// discriminates "route exists" vs "missing". Only features used for client
/// gating need an entry in [_featureProbes]; everything else (`houses`,
/// `checklists`, etc.) has existed since pre-capability releases and never
/// needs gating, so [hasFeature] returning `false` for them on an old server
/// is not a problem in practice. Probe results back-feed both [hasFeature]
/// and version-bound inference in [isServerPantryVersion], so callers don't
/// need to care which source the answer came from.
class ServerVersionService {
  ServerVersionService._();
  static final ServerVersionService instance = ServerVersionService._();

  /// Pantry feature → minimum version that introduced it. Used to bound the
  /// server version when the capability isn't reported. Keep in sync with
  /// what the Pantry backend will eventually publish under
  /// `capabilities.pantry.features`.
  static const Map<String, String> _featureIntroduced = {
    'category-sort': '0.15.0',
    'item-authors': '0.15.0',
  };

  /// Pantry feature → probe to run when capabilities don't cover it. The
  /// probe must be a no-op for both ancient and current backends; we send it
  /// on every login.
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

  final Map<String, bool> _features = {};
  bool _featuresAuthoritative = false;

  /// Reads `/ocs/v2.php/cloud/capabilities` and refreshes the version + feature
  /// state. With [serverUrl], runs unauthenticated against a prospective
  /// server (onboarding); without it, uses the logged-in session.
  ///
  /// Feature probes run only when the user is authenticated AND the
  /// capability response didn't already cover the feature.
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
      final response = await http.get(uri, headers: headers);
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
    } catch (e) {
      debugPrint('[ServerVersionService] Failed to fetch capabilities: $e');
    }

    if (creds != null) {
      await _runMissingProbes();
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

    final featuresField = pantryCaps['features'];
    if (featuresField is List) {
      // Capability features list is authoritative — anything the server
      // doesn't list is definitively unsupported. We skip probes for missing
      // features and [supportsFeature] stops failing open.
      _featuresAuthoritative = true;
      final listed = featuresField.whereType<String>().toSet();
      for (final name in listed) {
        _features[name] = true;
      }
      for (final name in _featureIntroduced.keys) {
        _features.putIfAbsent(name, () => listed.contains(name));
      }
    }
  }

  Future<void> _runMissingProbes() async {
    if (_featuresAuthoritative) return;
    for (final entry in _featureProbes.entries) {
      if (_features.containsKey(entry.key)) continue;
      _features[entry.key] = await _probe(entry.value);
    }
  }

  /// Lazy probe surface: callers that already have a house pref response can
  /// pass it in instead of forcing an extra request. The presence of the
  /// `showAddedBy` key in the response is the discriminator for
  /// `item-authors` (added in Pantry 0.15). Calls are no-ops once the feature
  /// status is known, or when the capability list is authoritative.
  void observeHousePrefs(Map<String, dynamic> prefs) {
    if (_featuresAuthoritative) return;
    _features.putIfAbsent(
      'item-authors',
      () => prefs.containsKey('showAddedBy'),
    );
  }

  Future<bool> _probe(_FeatureProbe spec) async {
    try {
      final uri = ApiClient.instance.buildUri(spec.path);
      final response = await http.post(
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
    _features.clear();
    _featuresAuthoritative = false;
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
  bool isServerPantryVersion(String op, String version) {
    return comparePantryVersion(
      op: op,
      target: Version.parse(version),
      known: _pantryVersion,
      features: _features,
      featureIntroduced: _featureIntroduced,
    );
  }

  /// Strict feature check, e.g. `hasFeature('category-sort')`. Returns `true`
  /// only when the server has *positively* confirmed support — either listed
  /// it in `capabilities.pantry.features`, or a probe succeeded. Unknown
  /// servers (no capability, no probe coverage) return `false`. Use this for
  /// genuinely new features that won't work on older servers.
  bool hasFeature(String name) => _features[name] ?? false;

  /// Fail-open feature check, e.g. `supportsFeature('soft-delete')`. Returns
  /// `false` only when the capability list is authoritative AND the feature
  /// is absent from it. On pre-capability servers (where the capability
  /// hasn't shipped yet) the answer defaults to `true`, so long-shipped
  /// features stay visible without needing a per-feature probe. Use this for
  /// features that have always existed but that the server might opt out of.
  bool supportsFeature(String name) {
    final known = _features[name];
    if (known != null) return known;
    if (_featuresAuthoritative) return false;
    return true;
  }

  @visibleForTesting
  void debugSeed({
    Version? pantryVersion,
    Map<String, bool> features = const {},
    bool featuresAuthoritative = false,
  }) {
    _pantryVersion = pantryVersion;
    _features
      ..clear()
      ..addAll(features);
    _featuresAuthoritative = featuresAuthoritative;
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

bool hasFeature(String name) => ServerVersionService.instance.hasFeature(name);

bool supportsFeature(String name) =>
    ServerVersionService.instance.supportsFeature(name);
