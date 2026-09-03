import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/cert_trust_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/house_service.dart';
import 'package:pantry_core/services/locale_service.dart';
import 'package:pantry_core/services/nn_localizations.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/theming_service.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry_wear/pantry_wear.dart';

/// Entrypoint for the `wear` flavor. Lives in the app package because
/// `--target` cannot point into a path dependency; everything it touches is
/// either core or the watch UI package.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Before anything reads a platform gate: a watch answers `true` to every
  // Android check, so nothing else can tell this binary from the phone's.
  PlatformInfo.markAsWatch();

  registerNnLocaleData();

  await Future.wait([
    AuthService.instance.loadCredentials(),
    PrefsService.instance.load(),
    CertTrustService.instance.load(),
  ]);
  CertTrustService.instance.install();
  AuthService.instance.hydrateFromCache();
  ThemingService.instance.loadCached();

  if (AuthService.instance.isLoggedIn) {
    await Future.wait([
      HouseService.instance.cache.load(),
      ChecklistService.instance.cache.load(),
    ]);
  }

  LocaleService.instance.apply();
  ApiClient.onForbidden = () {};
  runApp(const PantryWearApp());
}
