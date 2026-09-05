import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/category_service.dart';
import 'package:pantry_core/services/cert_trust_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/custom_field_service.dart';
import 'package:pantry_core/services/house_service.dart';
import 'package:pantry_core/services/label_service.dart';
import 'package:pantry_core/services/locale_service.dart';
import 'package:pantry_core/services/nn_localizations.dart';
import 'package:pantry_core/services/note_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/shopping_service.dart';
import 'package:pantry_core/services/store_service.dart';
import 'package:pantry_core/services/theming_service.dart';
import 'package:pantry_core/services/wear_mirror_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry_wear/pantry_wear.dart';

/// Entrypoint for the `wear` flavor. Lives in the app package because
/// `--target` cannot point into a path dependency; everything it touches is
/// either core or the watch UI package.
///
/// [args] carries the screen shape, which the activity reads from the window
/// configuration and passes here so layout has it before the first frame.
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Before anything reads a platform gate: a watch answers `true` to every
  // Android check, so nothing else can tell this binary from the phone's.
  PlatformInfo.markAsWatch();
  WearShape.markFrom(args);

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
      CategoryService.instance.cache.load(),
      StoreService.instance.cache.load(),
      // Every store a snapshot can land in, loaded before one can arrive: a
      // cache store rewrites its whole file per mutation, so landing into an
      // unloaded one replaces everything the last session left there.
      LabelService.instance.cache.load(),
      CustomFieldService.instance.cache.load(),
      NoteService.instance.cache.load(),
      ShoppingService.instance.cache.load(),
      WearMirrorService.instance.cache.load(),
      // Before anything can enqueue: the queue is written back whole on every
      // change, so a first enqueue against an unloaded queue replaces whatever
      // the last session left unsent with that single op.
      SyncManager.instance.init(),
    ]);
  }

  LocaleService.instance.apply();
  ApiClient.onForbidden = () {};
  runApp(const PantryWearApp());
  // After the first frame: the mirror only ever accelerates, so nothing it
  // does belongs on the path to drawing what the watch already knows.
  unawaited(WearMirrorClient.instance.start());
}
