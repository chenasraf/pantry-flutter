part of 'checklists_body_controller.dart';

extension ChecklistsBodyMenus on ChecklistsBodyController {
  HomeAppBarSpec buildAppBarSpec(BuildContext context, ChecklistList? list) {
    final cs = Theme.of(context).colorScheme;

    // While selecting, the shared AppBar becomes a contextual bar: close to
    // exit, and a live count. The group actions live in the bottom bar.
    if (domain.selectionMode) {
      return HomeAppBarSpec(
        hostRefresh: false,
        titleSpacing: 4,
        leadingWidth: 56,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: m.common.cancel,
          onPressed: domain.exitSelection,
        ),
        title: Text(
          m.checklists.batch.selected(domain.selectedCount),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: cs.onSurface,
          ),
        ),
      );
    }

    final isMeta = list?.id == kAllListsId;
    // Meta uses the theme accent, not list.color (which is null on the
    // sentinel) — gives it a distinct neutral feel from any specific list.
    final tint = isMeta
        ? cs.primary
        : (parseHexColor(list?.color) ?? cs.primary);
    final iconData = isMeta ? allListsIcon : checklistIcon(list?.icon);

    return HomeAppBarSpec(
      // Refresh sits among the checklist's own desktop actions below.
      hostRefresh: false,
      // titleSpacing is the gap between the leading slot and the title — set
      // to 11 to match the prior in-content header (SizedBox(width: 11)
      // between the cart tile and the list name).
      titleSpacing: 11,
      // leadingWidth = 20 (start padding) + 40 (icon tile). Combined with
      // titleSpacing:11, the layout matches the prior header exactly:
      // 20px from screen edge → 40px icon → 11px → title.
      leadingWidth: 60,
      leading: list == null
          ? null
          : Padding(
              padding: const EdgeInsetsDirectional.only(start: 20),
              // Align + SizedBox pin the tile to 40×40 — AppBar's leading
              // slot otherwise passes tight width constraints down through
              // Padding+InkWell and stretches the Container to fill.
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: InkWell(
                    onTap: () => openSwitcher(context),
                    borderRadius: BorderRadius.circular(SurfaceRadius.tile),
                    child: Container(
                      decoration: AppSurfaces.of(context).iconTile(tint),
                      child: Icon(iconData, color: tint, size: 20),
                    ),
                  ),
                ),
              ),
            ),
      title: list == null
          ? const SizedBox.shrink()
          : InkWell(
              key: switcherAnchorKey,
              onTap: () => openSwitcher(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        list.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: cs.onSurfaceVariant,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        IconButton(
          icon: Icon(searchOpen ? Icons.close : Icons.search),
          tooltip: searchOpen ? m.common.cancel : m.checklists.searchHint,
          onPressed: toggleSearch,
        ),
        // Reads the window width, so resizing re-decides which groups earn a
        // toolbar button and which fold into the overflow.
        Builder(builder: _toolbarActions),
      ],
    );
  }

  Widget _toolbarActions(BuildContext context) {
    final promoted = promotedGroupIds(context);
    final groups = {for (final g in overflowGroups()) g.id: g};
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final id in _toolbarPriority)
          if (promoted.contains(id) && groups[id] != null)
            _toolbarButton(context, groups[id]!),
        _overflowButton(context, promoted),
      ],
    );
  }

  /// Desktop toolbar groups, in the order they earn a button as the window
  /// widens. Pin is absent because the widget it feeds is Android-only.
  static const _toolbarPriority = [
    'view',
    'refresh',
    'manage',
    'trash',
    'archive',
  ];

  /// Groups shown as desktop toolbar buttons instead of in the overflow: as
  /// many of [_toolbarPriority] as the window has room for.
  Set<String> promotedGroupIds(BuildContext context) {
    if (!PlatformInfo.isDesktop || domain.isSoftView) return const {};
    // Room left once the nav rail, the list's icon and name, and the search
    // and overflow buttons have theirs.
    var slots = ((MediaQuery.sizeOf(context).width - 560) / 48).floor();
    final available = {for (final g in overflowGroups()) g.id};
    final promoted = <String>{};
    for (final id in _toolbarPriority) {
      if (slots <= 0) break;
      if (!available.contains(id)) continue;
      promoted.add(id);
      slots--;
    }
    return promoted;
  }

  Widget _toolbarButton(BuildContext context, OverflowGroup group) {
    final sole = group.soleEntry;
    if (sole is OverflowAction) {
      return IconButton(
        icon: Icon(sole.icon),
        tooltip: sole.label,
        onPressed: () => onOverflow(context, sole.value),
      );
    }
    return PopupMenuButton<String>(
      icon: Icon(group.icon),
      tooltip: group.label,
      onSelected: (v) => onOverflow(context, v),
      itemBuilder: (_) => overflowMenuItems(
        overflowGroups().where((g) => g.id == group.id).firstOrNull?.entries ??
            const [],
      ),
    );
  }

  Widget _overflowButton(BuildContext context, Set<String> promoted) {
    // The list style on desktop is an anchored popup menu; everything else
    // opens from a plain button.
    if (PlatformInfo.isDesktop && !_usesGrid) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        tooltip: m.common.more,
        onSelected: (v) => onOverflow(context, v),
        itemBuilder: (_) => overflowMenuItems(overflowItems(promoted)),
      );
    }
    return Builder(
      builder: (anchorContext) => IconButton(
        icon: const Icon(Icons.more_vert),
        tooltip: m.common.more,
        onPressed: () => showOverflowSheet(anchorContext, promoted),
      ),
    );
  }

  /// Whether the overflow shows the category grid. Trash and archive keep the
  /// plain list: their menus hold two or three rows.
  bool get _usesGrid =>
      PrefsService.instance.listMenuStyle == 'grid' && !domain.isSoftView;

  /// The overflow rows as one list, for the list menu style and the trash and
  /// archive views. Groups in [promoted] are on the toolbar and left out.
  List<OverflowEntry> overflowItems([Set<String> promoted = const {}]) {
    if (domain.isTrashMode) {
      return normalizeOverflow([
        OverflowAction(
          value: 'exit_trash',
          icon: Icons.arrow_back,
          label: m.checklists.exitTrash,
        ),
        // Bulk restore / permanent-delete need a selection; surface the entry
        // point here so it's reachable without a long-press (desktop).
        if (domain.canSelectItems && domain.items.isNotEmpty)
          OverflowAction(
            value: 'select_items',
            icon: Icons.checklist,
            label: m.checklists.selectItems,
          ),
        OverflowAction(
          value: 'empty_trash',
          icon: Icons.delete_forever,
          label: m.checklists.emptyTrash,
        ),
      ]);
    }
    // Archive has no "empty" action — archived items are kept indefinitely.
    if (domain.isArchiveMode) {
      return normalizeOverflow([
        OverflowAction(
          value: 'exit_archive',
          icon: Icons.arrow_back,
          label: m.checklists.exitArchive,
        ),
        // Bulk unarchive / permanent-delete need a selection; surface the
        // entry point here so it's reachable without a long-press (desktop).
        if (domain.canSelectItems && domain.items.isNotEmpty)
          OverflowAction(
            value: 'select_items',
            icon: Icons.checklist,
            label: m.checklists.selectItems,
          ),
      ]);
    }
    // Sort choices collapse to one "Sort: current" row that opens a dialog;
    // inlined, they would make the list menu much longer.
    return flattenOverflowGroups([
      for (final g in overflowGroups(inlineSort: false))
        if (!promoted.contains(g.id)) g,
    ]);
  }

  /// Every overflow action of the normal list view, grouped. Groups whose rows
  /// are all gated off come back empty and are dropped by the renderers.
  List<OverflowGroup> overflowGroups({bool inlineSort = true}) {
    final prefs = PrefsService.instance;
    final list = domain.currentList;
    final isMeta = domain.isMetaMode;
    final canEditLists = domain.permissions.canEditLists;
    final effective = domain.effectiveSortBy;
    return [
      OverflowGroup(
        id: 'select',
        icon: Icons.checklist,
        label: m.checklists.selectItems,
        entries: [
          if (domain.canSelectItems && domain.items.isNotEmpty)
            OverflowAction(
              value: 'select_items',
              icon: Icons.checklist,
              label: m.checklists.selectItems,
            ),
        ],
      ),
      OverflowGroup(
        id: 'view',
        icon: Icons.sort,
        label: m.checklists.menu.sortAndView,
        entries: [
          // In the meta (All-lists) view "custom" is suppressed: sort order is
          // per-list, so there's no coherent custom order across lists.
          if (inlineSort)
            for (final o in checklistSortOptions(showCustom: !isMeta))
              OverflowRadioAction(
                value: 'sort_${o.key}',
                label: o.label,
                selected: effective == o.key,
              )
          else
            OverflowAction(
              value: 'sort',
              icon: Icons.sort,
              label:
                  '${m.checklists.sortTooltip}: ${checklistSortLabel(effective)}',
            ),
          const OverflowDivider(),
          if (hasFeature('item-authors'))
            OverflowCheckboxAction(
              value: 'toggle_added_by',
              label: m.checklists.showAddedBy,
              checked: domain.showAddedBy,
            ),
          if (list != null)
            OverflowCheckboxAction(
              value: 'toggle_progress_hero',
              label: m.checklists.showProgressHero,
              checked: !list.hideProgressHero,
            ),
          // "Reset custom order" re-seeds sort_order from a chosen basis and
          // leaves the list hand-reorderable. Per-list only (no cross-list
          // custom order in meta) and needs edit permission.
          if (list != null && !isMeta && canEditLists) ...[
            const OverflowDivider(),
            OverflowAction(
              value: 'reset_order',
              icon: Icons.sort_by_alpha,
              label: m.checklists.resetOrder.menuLabel,
            ),
          ],
        ],
      ),
      OverflowGroup(
        id: 'manage',
        icon: Icons.dashboard_customize_outlined,
        label: m.checklists.menu.manage,
        entries: [
          if (!isMeta && list?.activeItemDefaults != null)
            OverflowAction(
              value: 'item_defaults',
              icon: Icons.tune,
              label: m.checklists.itemDefaults.title,
            ),
          const OverflowDivider(),
          if (canEditLists)
            OverflowAction(
              value: 'manage_categories',
              icon: EntityIcons.category,
              label: m.categories.manageTitle,
            ),
          if (canEditLists && hasFeature('stores'))
            OverflowAction(
              value: 'manage_stores',
              icon: EntityIcons.store,
              label: m.stores.manageTitle,
            ),
          if (canEditLists && hasFeature('labels'))
            OverflowAction(
              value: 'manage_labels',
              icon: EntityIcons.label,
              label: m.labels.manageTitle,
            ),
          if (domain.permissions.canEditFields && hasFeature('custom-fields'))
            OverflowAction(
              value: 'manage_custom_fields',
              icon: Icons.list_alt,
              label: m.customFields.manageTitle,
            ),
        ],
      ),
      OverflowGroup(
        id: 'list',
        icon: Icons.format_list_bulleted,
        label: m.checklists.menu.list,
        entries: [
          if (list != null && domain.canDuplicateList(list))
            OverflowAction(
              value: 'duplicate_list',
              icon: Icons.copy_outlined,
              label: m.checklists.duplicateListTitle,
            ),
          if (list != null && !isMeta && PlatformInfo.isMobile)
            OverflowAction(
              value: 'copy_link',
              icon: Icons.link,
              label: m.checklists.copyLink,
            ),
          if (list != null && !isMeta && PlatformInfo.isAndroidPhone)
            OverflowAction(
              value: 'add_to_home',
              icon: Icons.add_to_home_screen,
              label: m.checklists.addToHomeScreen,
            ),
          // Markdown import/export are per-list only — not offered in the meta
          // "All lists" view, which has no single target.
          if (list != null && !isMeta) ...[
            const OverflowDivider(),
            OverflowAction(
              value: 'export_markdown',
              icon: Icons.file_download_outlined,
              label: m.checklists.markdown.exportTitle,
            ),
            if (domain.canAddItemsHere)
              OverflowAction(
                value: 'import_markdown',
                icon: Icons.file_upload_outlined,
                label: m.checklists.markdown.importTitle,
              ),
          ],
        ],
      ),
      OverflowGroup(
        id: 'shopping',
        icon: Icons.shopping_cart_outlined,
        label: m.checklists.menu.shopping,
        entries: [
          if (hasFeature('shopping')) ...[
            // When the FAB is turned off, its action lives here, above history.
            if (!prefs.startShoppingFabEnabled)
              OverflowAction(
                value: 'start_shopping',
                icon: shoppingSession != null
                    ? Icons.play_arrow
                    : Icons.shopping_cart,
                label: shoppingSession != null
                    ? m.shopping.resumeShopping
                    : m.shopping.startShopping,
              ),
            OverflowAction(
              value: 'shopping_history',
              icon: Icons.history,
              label: m.shopping.shoppingHistory,
            ),
          ],
        ],
      ),
      // Trash and archive are per-list; the meta view has neither.
      OverflowGroup(
        id: 'trash',
        icon: Icons.delete_outline,
        label: m.checklists.viewTrash,
        entries: [
          if (!isMeta &&
              domain.isCurrentListWritable &&
              domain.permissions.canDeleteItems &&
              (supportsFeature('soft-delete') || hasFeature('item-trash')))
            OverflowAction(
              value: 'view_trash',
              icon: Icons.delete_outline,
              label: m.checklists.viewTrash,
            ),
        ],
      ),
      OverflowGroup(
        id: 'archive',
        icon: Icons.archive_outlined,
        label: m.checklists.viewArchive,
        entries: [
          if (!isMeta &&
              domain.isCurrentListWritable &&
              canEditLists &&
              hasFeature('item-archive'))
            OverflowAction(
              value: 'view_archive',
              icon: Icons.archive_outlined,
              label: m.checklists.viewArchive,
            ),
        ],
      ),
      // Mobile has pull-to-refresh; desktop has no such gesture.
      OverflowGroup(
        id: 'refresh',
        icon: Icons.refresh,
        label: m.common.refresh,
        entries: [
          if (PlatformInfo.isDesktop)
            OverflowAction(
              value: 'refresh',
              icon: Icons.refresh,
              label: m.common.refresh,
            ),
        ],
      ),
      OverflowGroup(
        id: 'developer',
        icon: Icons.bug_report_outlined,
        label: m.checklists.menu.developer,
        entries: [
          if (kDebugMode) ...[
            OverflowAction(
              value: 'dev_show_onboarding',
              icon: Icons.bug_report_outlined,
              label: m.onboarding.dev.showOnboarding,
            ),
            OverflowCheckboxAction(
              value: 'dev_force_all_features',
              label: m.onboarding.dev.forceAllFeatures,
              checked: prefs.devForceAllFeatures,
            ),
            OverflowAction(
              value: 'dev_test_notification',
              icon: Icons.notifications_active_outlined,
              label: m.onboarding.dev.sendTestNotification,
            ),
          ],
        ],
      ),
    ].map((g) => g.normalized()).where((g) => !g.isEmpty).toList();
  }
}
