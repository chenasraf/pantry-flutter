import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/cache_store.dart';
import 'package:pantry_core/services/cert_trust_service.dart';
import 'package:pantry_core/services/locale_service.dart';
import 'package:pantry_core/services/nn_localizations.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/reachability_service.dart';
import 'package:pantry_core/services/theming_service.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry_wear/pantry_wear.dart';

/// Entrypoint for the `wear` flavor. Lives in the app package because
/// `--target` cannot point into a path dependency; everything it touches is
/// either core or the watch UI package.
///
/// [args] carries the screen shape and, when the app was launched from the
/// list Tile or a `pantry://list/...` intent, the list to open. Both are read
/// from the launch intent in `onCreate` and passed here so the first frame is
/// already the right one.
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Before anything reads a platform gate: a watch answers `true` to every
  // Android check, so nothing else can tell this binary from the phone's.
  PlatformInfo.markAsWatch();
  WearShape.markFrom(args);
  WearDeepLink.instance.markFrom(args);
  // Core's image providers have no store until one is installed, and the
  // watch's is not the phone's.
  WearImageCache.install();

  registerNnLocaleData();

  await Future.wait([
    AuthService.instance.loadCredentials(),
    PrefsService.instance.load(),
    CertTrustService.instance.load(),
  ]);
  CertTrustService.instance.install();
  AuthService.instance.hydrateFromCache();
  ThemingService.instance.loadCached();

  if (AuthService.instance.isLoggedIn) await loadWearStores();

  // Scope moves before the first frame rather than after it. Applying a Tile
  // tap later would draw the list the watch was last on, then swap — which is
  // the reflow the shape argument exists to avoid, on the one launch where the
  // wearer named the destination themselves.
  await WearDeepLink.instance.applyPending();

  LocaleService.instance.apply();
  ApiClient.onForbidden = () {};
  // A watch process is killed far more readily than a phone's, so the pause is
  // where a debounced cache write has to land.
  CacheStore.installPauseCheckpoint();
  ReachabilityService.instance.start();
  runApp(const PantryWearApp());
  // After the first frame: the mirror only ever accelerates, so nothing it
  // does belongs on the path to drawing what the watch already knows.
  unawaited(WearMirrorClient.instance.start());
  unawaited(WearDeepLink.instance.start());
}
