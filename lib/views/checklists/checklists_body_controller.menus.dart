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
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: tint.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
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
        // Desktop has plenty of room — promote the top four actions out of
        // the overflow menu so they're a single click away. Pin is not
        // surfaced anywhere on desktop because the widget it feeds is
        // Android-only.
        if (PlatformInfo.isDesktop && !domain.isSoftView) ...[
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: m.checklists.sortTooltip,
            onSelected: (v) => onOverflow(context, v),
            itemBuilder: (_) => sortMenuItems(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: m.common.refresh,
            onPressed: () => domain.refresh(),
          ),
          if (domain.permissions.canEditLists)
            IconButton(
              icon: const Icon(EntityIcons.category),
              tooltip: m.categories.manageTitle,
              onPressed: () => openManageCategories(context),
            ),
          if (domain.permissions.canEditLists && hasFeature('stores'))
            IconButton(
              icon: const Icon(EntityIcons.store),
              tooltip: m.stores.manageTitle,
              onPressed: () => openManageStores(context),
            ),
          if (domain.permissions.canEditLists && hasFeature('labels'))
            IconButton(
              icon: const Icon(EntityIcons.label),
              tooltip: m.labels.manageTitle,
              onPressed: () => openManageLabels(context),
            ),
          if (domain.permissions.canEditFields && hasFeature('custom-fields'))
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: m.customFields.manageTitle,
              onPressed: () => openManageCustomFields(context),
            ),
          // Meta view has no trash of its own; trash stays per-list.
          if (!domain.isMetaMode &&
              domain.isCurrentListWritable &&
              domain.permissions.canDeleteItems &&
              (supportsFeature('soft-delete') || hasFeature('item-trash')))
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: m.checklists.viewTrash,
              onPressed: () => domain.setTrashMode(true),
            ),
          // Archive is per-list too, gated on canEditLists and the
          // item-archive capability.
          if (!domain.isMetaMode &&
              domain.isCurrentListWritable &&
              domain.permissions.canEditLists &&
              hasFeature('item-archive'))
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: m.checklists.viewArchive,
              onPressed: () => domain.setArchiveMode(true),
            ),
        ],
        // Desktop shows the overflow as an anchored popup menu; mobile keeps
        // it in a bottom sheet, which reads and scrolls better on touch.
        if (PlatformInfo.isDesktop)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: m.common.more,
            onSelected: (v) => onOverflow(context, v),
            itemBuilder: (_) => overflowMenuItems(overflowItems()),
          )
        else
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: m.common.more,
            onPressed: () => showOverflowSheet(context),
          ),
      ],
    );
  }

  /// Sort radio rows lifted out of `overflowItems` so the desktop toolbar's
  /// Sort menu can show only the sort choices, not the rest of the overflow.
  ///
  /// In the meta (All-lists) view, "custom" is suppressed: the underlying
  /// sort order is per-list, so there's no coherent custom order across
  /// lists. The effective sort falls back to "newest".
  List<PopupMenuEntry<String>> sortMenuItems() {
    final effective = domain.effectiveSortBy;
    return [
      for (final o in checklistSortOptions(showCustom: !domain.isMetaMode))
        overflowRadioRow(
          value: 'sort_${o.key}',
          label: o.label,
          selected: effective == o.key,
        ),
    ];
  }

  List<OverflowEntry> overflowItems() {
    final prefs = PrefsService.instance;
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
    // Desktop has promoted refresh / sort / categories / trash to dedicated
    // toolbar buttons, and pinning lists feeds an Android-only widget, so
    // none of those need to live in the overflow menu here. Everything left
    // — the view toggles and the dev tools — stays in overflow on every
    // platform.
    final isMeta = domain.isMetaMode;
    final effective = domain.effectiveSortBy;
    return normalizeOverflow([
      if (domain.canSelectItems && domain.items.isNotEmpty) ...[
        OverflowAction(
          value: 'select_items',
          icon: Icons.checklist,
          label: m.checklists.selectItems,
        ),
        const OverflowDivider(),
      ],
      if (!PlatformInfo.isDesktop) ...[
        OverflowAction(
          value: 'sort',
          icon: Icons.sort,
          label:
              '${m.checklists.sortTooltip}: ${checklistSortLabel(effective)}',
        ),
        const OverflowDivider(),
        if (domain.currentList != null && !isMeta && PlatformInfo.isMobile)
          OverflowAction(
            value: 'copy_link',
            icon: Icons.link,
            label: m.checklists.copyLink,
          ),
        if (domain.currentList != null &&
            !isMeta &&
            PlatformInfo.isAndroidPhone)
          OverflowAction(
            value: 'add_to_home',
            icon: Icons.add_to_home_screen,
            label: m.checklists.addToHomeScreen,
          ),
      ],
      if (hasFeature('item-authors'))
        OverflowCheckboxAction(
          value: 'toggle_added_by',
          label: m.checklists.showAddedBy,
          checked: domain.showAddedBy,
        ),
      if (domain.currentList != null)
        OverflowCheckboxAction(
          value: 'toggle_progress_hero',
          label: m.checklists.showProgressHero,
          checked: !(domain.currentList!.hideProgressHero),
        ),
      // "Reset custom order" re-seeds sort_order from a chosen basis and leaves
      // the list hand-reorderable. Per-list only (no cross-list custom order in
      // meta) and needs edit permission.
      if (domain.currentList != null &&
          !isMeta &&
          domain.permissions.canEditLists) ...[
        const OverflowDivider(),
        OverflowAction(
          value: 'reset_order',
          icon: Icons.sort_by_alpha,
          label: m.checklists.resetOrder.menuLabel,
        ),
      ],
      // Markdown import/export are per-list only — not offered in the meta
      // "All lists" view, which has no single target.
      if (domain.currentList != null && !isMeta) ...[
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
      if (hasFeature('shopping')) ...[
        const OverflowDivider(),
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
        const OverflowDivider(),
      ],
      if (!PlatformInfo.isDesktop) ...[
        if (domain.permissions.canEditLists)
          OverflowAction(
            value: 'manage_categories',
            icon: EntityIcons.category,
            label: m.categories.manageTitle,
          ),
        if (domain.permissions.canEditLists && hasFeature('stores'))
          OverflowAction(
            value: 'manage_stores',
            icon: EntityIcons.store,
            label: m.stores.manageTitle,
          ),
        if (domain.permissions.canEditLists && hasFeature('labels'))
          OverflowAction(
            value: 'manage_labels',
            icon: EntityIcons.label,
            label: m.labels.manageTitle,
          ),
        if (domain.permissions.canEditFields && hasFeature('custom-fields'))
          OverflowAction(
            value: 'manage_custom_fields',
            icon: Icons.tune,
            label: m.customFields.manageTitle,
          ),
        // Mobile has reliable pull-to-refresh, so it doesn't need a menu row.
        // Web (the other non-desktop host here) doesn't, so keep it there.
        if (PlatformInfo.isWeb)
          OverflowAction(
            value: 'refresh',
            icon: Icons.refresh,
            label: m.common.refresh,
          ),
        if (!isMeta &&
            domain.isCurrentListWritable &&
            domain.permissions.canDeleteItems &&
            (supportsFeature('soft-delete') || hasFeature('item-trash'))) ...[
          const OverflowDivider(),
          OverflowAction(
            value: 'view_trash',
            icon: Icons.delete_outline,
            label: m.checklists.viewTrash,
          ),
        ],
        if (!isMeta &&
            domain.isCurrentListWritable &&
            domain.permissions.canEditLists &&
            hasFeature('item-archive'))
          OverflowAction(
            value: 'view_archive',
            icon: Icons.archive_outlined,
            label: m.checklists.viewArchive,
          ),
      ],
      if (kDebugMode) ...[
        const OverflowDivider(),
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
    ]);
  }
}
