import 'package:pantry_core/services/category_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/custom_field_service.dart';
import 'package:pantry_core/services/house_service.dart';
import 'package:pantry_core/services/label_service.dart';
import 'package:pantry_core/services/note_service.dart';
import 'package:pantry_core/services/shopping_service.dart';
import 'package:pantry_core/services/store_service.dart';
import 'package:pantry_core/services/wear_mirror_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';

import 'services/wear_tile_service.dart';

/// Every store the watch reads or writes, loaded before anything can touch
/// one.
///
/// A cache store rewrites its whole file per mutation, so a write against an
/// unloaded store replaces everything the last session left there — and a
/// snapshot can land in any of these the moment the link is up. The sync queue
/// is the same hazard with a worse outcome: a first enqueue against an
/// unloaded queue drops every write still waiting to be sent.
///
/// One list, called from both paths that reach a signed-in watch: the boot
/// that finds a credential already stored, and the pairing that has just
/// received one.
/// Drop everything [loadWearStores] loaded, plus the mirror's arrival record —
/// dated snapshots describing caches that no longer exist would outlive them.
///
/// `SyncManager.reset()` rather than a bare cache clear: the queue holds the
/// wearer's unsent intent, and dropping the file without the manager's own
/// teardown would leave it re-saving what it still held in memory.
///
/// The Tile snapshot goes with them. It is a copy of the same household names,
/// held outside every store here because the Tile is drawn with no engine
/// running — so a clear that stopped at the caches would leave the list names
/// on the watch face of a watch that no longer has an account.
Future<void> clearWearStores() => Future.wait([
  HouseService.instance.cache.clear(),
  ChecklistService.instance.cache.clear(),
  CategoryService.instance.cache.clear(),
  StoreService.instance.cache.clear(),
  LabelService.instance.cache.clear(),
  CustomFieldService.instance.cache.clear(),
  NoteService.instance.cache.clear(),
  ShoppingService.instance.cache.clear(),
  WearMirrorService.instance.clear(),
  SyncManager.instance.reset(),
  WearTileService.instance.clear(),
]);

Future<void> loadWearStores() => Future.wait([
  HouseService.instance.cache.load(),
  ChecklistService.instance.cache.load(),
  CategoryService.instance.cache.load(),
  StoreService.instance.cache.load(),
  LabelService.instance.cache.load(),
  CustomFieldService.instance.cache.load(),
  NoteService.instance.cache.load(),
  ShoppingService.instance.cache.load(),
  WearMirrorService.instance.cache.load(),
  SyncManager.instance.init(),
]);
