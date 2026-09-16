import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/category.dart' as models;
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/models/shopping_reminder.dart';
import 'package:pantry_core/models/shopping_session.dart';
import 'package:pantry_core/models/store.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/category_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/house_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/services/shopping_service.dart';
import 'package:pantry_core/services/store_service.dart';
import 'package:pantry_core/utils/checklist_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/store_icons.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry/utils/app_toast.dart';
import 'package:pantry/views/shopping/shopping_item_picker_view.dart';
import 'package:pantry/views/shopping/shopping_reminder_block.dart';
import 'package:pantry/views/shopping/shopping_reminders_view.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';

/// The start screen: pick lists to shop, toggle & order the stores you'll
/// visit, choose whether to include unassigned items, then start. Guards the
/// one-live-session-per-user rule — if a trip is already in progress it offers
/// Resume / End previous instead of the picker.
///
/// Pops a [ShoppingSession] when the caller should navigate into a live session
/// (freshly created, or resumed); pops null / nothing otherwise.
class ShoppingStartView extends StatefulWidget {
  final int houseId;

  /// Optional list to preselect (e.g. the list the user was viewing). When
  /// null, all lists start selected.
  final int? preselectListId;

  const ShoppingStartView({
    super.key,
    required this.houseId,
    this.preselectListId,
  });

  @override
  State<ShoppingStartView> createState() => _ShoppingStartViewState();
}

class _ShoppingStartViewState extends State<ShoppingStartView> {
  ShoppingService get _shopping => ShoppingService.instance;

  bool _loading = true;
  String? _error;
  bool _submitting = false;

  List<ChecklistList> _lists = [];
  final Set<int> _selectedListIds = {};
  final Map<int, List<ListItem>> _itemsByList = {};
  Map<int, Store> _stores = {};
  Map<int, models.Category> _categories = {};

  /// Items the shopper has taken off the plan, tracked as an exclusion rather
  /// than a selection so anything that enters scope afterwards — a list
  /// re-checked, a housemate's new item — is shopped by default.
  final Set<int> _excludedItemIds = {};

  /// House store-order preference (`name_asc` | `name_desc` | `custom`). Seeds
  /// the trip's default store order; the shopper still drags to reorder for the
  /// trip only.
  String _storeSort = 'name_asc';

  /// Available stores in display/drag order (those referenced by un-done items
  /// on the selected lists). Enabled ones, in this order, are sent on start.
  List<int> _orderedStoreIds = [];
  final Set<int> _enabledStoreIds = {};

  bool _includeUnassigned = true;
  List<ShoppingReminder> _startReminders = [];

  /// A live session found on mount — shows the Resume / End guard instead.
  /// Not necessarily the caller's own: a trip they joined blocks a new one too.
  ShoppingSession? _guardSession;

  final String? _currentUserId = AuthService.instance.credentials?.loginName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Guard first — a live session (any house) blocks starting a new one.
      final current = await _shopping.getCurrentSession();
      if (!mounted) return;
      if (current != null && current.live) {
        setState(() {
          _guardSession = current;
          _loading = false;
        });
        return;
      }

      final results = await Future.wait([
        ChecklistService.instance.getLists(widget.houseId),
        StoreService.instance.getStores(widget.houseId),
        _shopping
            .getReminders(widget.houseId)
            .catchError((_) => <ShoppingReminder>[]),
        ChecklistService.instance
            .getHousePrefs(widget.houseId)
            .catchError((_) => <String, dynamic>{}),
        CategoryService.instance
            .getCategories(widget.houseId)
            .catchError((_) => <models.Category>[]),
      ]);
      if (!mounted) return;
      final lists = (results[0] as List<ChecklistList>)
          .where((l) => l.id > 0)
          .toList();
      _stores = {for (final s in results[1] as List<Store>) s.id: s};
      _categories = {
        for (final c in results[4] as List<models.Category>) c.id: c,
      };
      _storeSort =
          (results[3] as Map<String, dynamic>)['storeSort'] as String? ??
          'name_asc';
      _startReminders =
          (results[2] as List<ShoppingReminder>)
              .where(
                (r) => r.enabled && r.showOn == ShoppingReminderMoment.onStart,
              )
              .toList()
            ..sort((a, b) => a.position.compareTo(b.position));

      _lists = lists;
      _selectedListIds
        ..clear()
        ..addAll(
          widget.preselectListId != null &&
                  lists.any((l) => l.id == widget.preselectListId)
              ? {widget.preselectListId!}
              : lists.map((l) => l.id),
        );

      // Load each list's items (cache-first) to derive the store set.
      await Future.wait(
        lists.map((l) async {
          final cached = ChecklistService.instance.getCachedItems(l.id);
          if (cached != null) {
            _itemsByList[l.id] = cached;
            return;
          }
          try {
            _itemsByList[l.id] = await ChecklistService.instance.getItems(
              widget.houseId,
              l.id,
            );
          } catch (_) {
            _itemsByList[l.id] = const [];
          }
        }),
      );
      if (!mounted) return;
      _recomputeStores();
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = m.shopping.loadFailed;
      });
    }
  }

  /// Recompute which stores are offered from the selected lists' un-done items.
  /// Preserves the order & enabled state of stores that remain available;
  /// newly-available stores are appended and default to enabled.
  void _recomputeStores() {
    final available = <int>{};
    for (final listId in _selectedListIds) {
      for (final item in _itemsByList[listId] ?? const <ListItem>[]) {
        if (item.done || item.deletedAt != null || item.archivedAt != null) {
          continue;
        }
        available.addAll(item.storeIds.where(_stores.containsKey));
      }
    }
    final kept = [
      for (final id in _orderedStoreIds)
        if (available.contains(id)) id,
    ];
    // Seed newly-available stores in the house's store order (name or custom,
    // per the storeSort pref) rather than a hardcoded name sort. The shopper
    // still drags to reorder for the trip only.
    final rank = <int, int>{};
    final houseOrder = StoreService.sortStores(_stores.values, _storeSort);
    for (var i = 0; i < houseOrder.length; i++) {
      rank[houseOrder[i].id] = i;
    }
    final added = [
      for (final id in available)
        if (!kept.contains(id)) id,
    ]..sort((a, b) => (rank[a] ?? 1 << 30).compareTo(rank[b] ?? 1 << 30));
    _orderedStoreIds = [...kept, ...added];
    _enabledStoreIds
      ..removeWhere((id) => !available.contains(id))
      ..addAll(added);
  }

  /// The items a trip over the currently selected lists would cover. Matches
  /// what the server treats as in scope, so neither the store sequence nor
  /// [_includeUnassigned] narrows it.
  List<ListItem> get _candidateItems => [
    for (final list in _lists)
      if (_selectedListIds.contains(list.id))
        for (final item in _itemsByList[list.id] ?? const <ListItem>[])
          if (!item.done && item.deletedAt == null && item.archivedAt == null)
            item,
  ];

  List<int> _includedItemIds(List<ListItem> candidates) => [
    for (final item in candidates)
      if (!_excludedItemIds.contains(item.id)) item.id,
  ];

  Future<void> _openItemPicker() async {
    final result = await pickShoppingItems(
      context,
      items: _candidateItems,
      categories: _categories,
      excludedItemIds: _excludedItemIds,
    );
    if (result == null || !mounted) return;
    setState(() {
      _excludedItemIds
        ..clear()
        ..addAll(result);
    });
  }

  void _toggleList(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedListIds.add(id);
      } else {
        _selectedListIds.remove(id);
      }
      _recomputeStores();
    });
  }

  void _selectAllLists(bool all) {
    setState(() {
      _selectedListIds.clear();
      if (all) _selectedListIds.addAll(_lists.map((l) => l.id));
      _recomputeStores();
    });
  }

  void _reorderStores(int oldIndex, int newIndex) {
    setState(() {
      final moved = _orderedStoreIds.removeAt(oldIndex);
      _orderedStoreIds.insert(newIndex, moved);
    });
  }

  Future<void> _start() async {
    if (_selectedListIds.isEmpty || _submitting) return;
    final candidates = _candidateItems;
    final included = _includedItemIds(candidates);
    // A trip covering nothing has no representation on the wire — an empty
    // list reads as "shop everything", the opposite of what was asked.
    if (candidates.isNotEmpty && included.isEmpty) return;
    setState(() => _submitting = true);
    final storeIds = [
      for (final id in _orderedStoreIds)
        if (_enabledStoreIds.contains(id)) id,
    ];
    try {
      final session = await _shopping.createSession(
        widget.houseId,
        listIds: _selectedListIds.toList(),
        storeIds: storeIds,
        includeUnassigned: _includeUnassigned,
        // A full trip sends nothing rather than every id, which is what a
        // server without the capability sees either way.
        itemIds: included.length == candidates.length ? null : included,
      );
      if (!mounted) return;
      Navigator.of(context).pop(session);
    } on ShoppingSessionConflict catch (conflict) {
      if (!mounted) return;
      setState(() {
        _guardSession = conflict.session;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showAppToast(message: m.shopping.startFailed, kind: ToastKind.error);
    }
  }

  Future<void> _resumeGuard() async {
    Navigator.of(context).pop(_guardSession);
  }

  /// Clear the guard so a new trip can start. A trip the shopper merely joined
  /// is someone else's: stepping out of it clears the way, whereas closing it
  /// would end a housemate's trip from a screen that promised nothing of the
  /// sort.
  Future<void> _endPrevious() async {
    final session = _guardSession;
    if (session == null) return;
    final mine = session.isStartedBy(_currentUserId);
    setState(() => _submitting = true);
    try {
      if (mine) {
        await _shopping.close(session.houseId, session.id);
      } else {
        await _shopping.leaveSession(session.houseId, session.id);
      }
    } on ShoppingSessionConflict {
      // Already closed — fine, proceed to the picker.
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showAppToast(
        message: mine
            ? m.shopping.endPreviousFailed
            : m.shopping.leaveTripFailed,
        kind: ToastKind.error,
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _guardSession = null;
      _submitting = false;
    });
    await _load();
  }

  Future<void> _openReminders() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShoppingRemindersView(houseId: widget.houseId),
      ),
    );
    // Refresh the on_start block in case reminders changed.
    try {
      final reminders = await _shopping.getReminders(widget.houseId);
      if (!mounted) return;
      setState(() {
        _startReminders =
            reminders
                .where(
                  (r) =>
                      r.enabled && r.showOn == ShoppingReminderMoment.onStart,
                )
                .toList()
              ..sort((a, b) => a.position.compareTo(b.position));
      });
    } catch (_) {
      /* keep what we have */
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: appBarBackLeading(context),
        title: Text(m.shopping.startTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorRetry(message: _error!, onRetry: _load)
          : _guardSession != null
          ? _buildGuard()
          : _buildPicker(),
    );
  }

  Widget _buildGuard() {
    final theme = Theme.of(context);
    final session = _guardSession!;
    final mine = session.isStartedBy(_currentUserId);
    final sameHouse = session.houseId == widget.houseId;
    final houseName = HouseService.instance
        .getCached()
        ?.cast<House?>()
        .firstWhere((h) => h!.id == session.houseId, orElse: () => null)
        ?.name;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    !mine
                        ? m.shopping.tripWithHousemate
                        : sameHouse || houseName == null
                        ? m.shopping.tripInProgress
                        : m.shopping.tripInProgressElsewhere(houseName),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _resumeGuard,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(m.shopping.resume),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _submitting ? null : _endPrevious,
                    child: Text(
                      mine ? m.shopping.endPreviousTrip : m.shopping.leaveTrip,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPicker() {
    final theme = Theme.of(context);
    final allSelected = _selectedListIds.length == _lists.length;
    final candidates = _candidateItems;
    final included = _includedItemIds(candidates);
    final nothingPicked = candidates.isNotEmpty && included.isEmpty;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ShoppingReminderBlock(
                reminders: _startReminders,
                onManage: _openReminders,
              ),
              const SizedBox(height: 16),
              // Lists section.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      m.shopping.listsToShop,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (_lists.isNotEmpty)
                    TextButton(
                      onPressed: () => _selectAllLists(!allSelected),
                      child: Text(
                        allSelected
                            ? m.shopping.selectNone
                            : m.shopping.selectAll,
                      ),
                    ),
                ],
              ),
              if (_lists.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    m.shopping.noListsToShop,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                for (final list in _lists)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _selectedListIds.contains(list.id),
                    onChanged: (v) => _toggleList(list.id, v ?? false),
                    secondary: Icon(checklistIcon(list.icon)),
                    title: Text(
                      list.name,
                      textDirection: detectTextDirection(list.name),
                    ),
                  ),
              const SizedBox(height: 16),
              // Stores section.
              Text(m.shopping.storesTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                m.shopping.storesHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              if (_orderedStoreIds.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    m.shopping.noStoresWithItems,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: _orderedStoreIds.length,
                  onReorderItem: _reorderStores,
                  itemBuilder: (context, index) {
                    final id = _orderedStoreIds[index];
                    final store = _stores[id];
                    return _StoreToggleRow(
                      key: ValueKey(id),
                      index: index,
                      name: store?.name ?? '',
                      icon: storeIcon(store?.icon),
                      color: parseHexColor(store?.color),
                      enabled: _enabledStoreIds.contains(id),
                      onToggle: (v) => setState(() {
                        if (v) {
                          _enabledStoreIds.add(id);
                        } else {
                          _enabledStoreIds.remove(id);
                        }
                      }),
                    );
                  },
                ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _includeUnassigned,
                onChanged: (v) => setState(() => _includeUnassigned = v),
                title: Text(m.shopping.includeUnassigned),
              ),
              if (hasFeature('shopping-item-selection')) ...[
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: candidates.isNotEmpty,
                  leading: const Icon(Icons.checklist),
                  title: Text(m.shopping.itemsToShop),
                  subtitle: Text(
                    candidates.isEmpty
                        ? m.shopping.noItemsToShop
                        : included.length == candidates.length
                        ? m.shopping.allItemsPicked(candidates.length)
                        : m.shopping.someItemsPicked(
                            included.length,
                            candidates.length,
                          ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: candidates.isEmpty ? null : _openItemPicker,
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (nothingPicked)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 8),
                    child: Text(
                      m.shopping.pickAtLeastOneItem,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        (_selectedListIds.isEmpty ||
                            nothingPicked ||
                            _submitting)
                        ? null
                        : _start,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.shopping_cart_checkout),
                    label: Text(m.shopping.start),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StoreToggleRow extends StatelessWidget {
  final int index;
  final String name;
  final IconData icon;
  final Color? color;
  final bool enabled;
  final ValueChanged<bool> onToggle;

  const _StoreToggleRow({
    super.key,
    required this.index,
    required this.name,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.drag_handle, size: 20),
            ),
          ),
          Icon(icon, color: color ?? cs.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              textDirection: detectTextDirection(name),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Switch(value: enabled, onChanged: onToggle),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(m.common.retry)),
          ],
        ),
      ),
    );
  }
}
