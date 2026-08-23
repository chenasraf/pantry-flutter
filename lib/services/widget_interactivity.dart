import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import '../models/checklist.dart';
import '../sync/sync_ids.dart';
import '../sync/sync_manager.dart';
import '../sync/sync_op.dart';
import 'auth_service.dart';
import 'category_service.dart';
import 'cert_trust_service.dart';
import 'checklist_service.dart';
import 'checklist_widget_service.dart';
import 'label_service.dart';
import 'store_service.dart';

/// Register the interactive-widget callback so checkbox/row taps on the
/// single-checklist widget reach [widgetInteractivityCallback]. Call once from
/// the foreground engine (main).
void registerWidgetInteractivity() {
  HomeWidget.registerInteractivityCallback(widgetInteractivityCallback);
}

/// Runs in a background isolate when the checklist widget's checkbox is tapped
/// (via [WidgetActionActivity] → home_widget broadcast). Flips the item
/// done/undone offline. Row "open" taps are handled natively by the trampoline.
@pragma('vm:entry-point')
Future<void> widgetInteractivityCallback(Uri? uri) async {
  if (uri == null) return;
  WidgetsFlutterBinding.ensureInitialized();
  if (uri.host == 'toggle') await _toggle(uri);
}

Future<void> _toggle(Uri uri) async {
  final segs = uri.pathSegments;
  if (segs.length < 4) return;
  final houseId = int.tryParse(segs[0]);
  final listId = int.tryParse(segs[1]);
  final itemId = int.tryParse(segs[2]);
  final widgetId = int.tryParse(segs[3]);
  if (houseId == null || listId == null || itemId == null || widgetId == null) {
    return;
  }

  await AuthService.instance.loadCredentials();
  await CertTrustService.instance.load();
  CertTrustService.instance.install();
  await Future.wait([
    ChecklistService.instance.cache.load(),
    CategoryService.instance.cache.load(),
    StoreService.instance.cache.load(),
    LabelService.instance.cache.load(),
  ]);

  final items = List<ListItem>.of(
    ChecklistService.instance.getCachedItems(listId) ?? const <ListItem>[],
  );
  final index = items.indexWhere((i) => i.id == itemId);
  if (index == -1) return;
  final item = items[index];
  items[index] = item.copyWith(
    done: !item.done,
    updatedAt: DateTime.now().millisecondsSinceEpoch,
  );
  ChecklistService.instance.cacheItems(listId, items);

  await SyncManager.instance.init();
  SyncManager.instance.enqueue(
    SyncOp(
      uuid: SyncIds.newOpUuid(),
      entity: SyncEntity.checklistItem,
      op: SyncOpKind.toggle,
      houseId: houseId,
      parentId: listId,
      entityId: itemId < 0 ? null : itemId,
      tempEntityId: itemId < 0 ? itemId : null,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
  );

  // Re-render just this widget. refreshAll() can't run here: enumerating widget
  // ids needs a MethodChannel that only exists in the app's activities, not this
  // background isolate. The lists widget's counts refresh on the next app resume.
  await ChecklistWidgetService.instance.refresh(widgetId);
}
