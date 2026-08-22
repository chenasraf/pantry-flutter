import 'package:flutter/material.dart';

import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/utils/version.dart';
import 'pages/add_items_page.dart';
import 'pages/all_lists_page.dart';
import 'pages/barcode_scan_page.dart';
import 'pages/bulk_add_page.dart';
import 'pages/bulk_select_page.dart';
import 'pages/category_scope_page.dart';
import 'pages/checklist_selector_page.dart';
import 'pages/checklists_redesign_intro_page.dart';
import 'pages/item_price_page.dart';
import 'pages/pinned_notes_page.dart';
import 'pages/progress_hero_dismiss_page.dart';
import 'pages/progress_hero_page.dart';
import 'pages/quick_actions_page.dart';
import 'pages/shopping_mode_page.dart';
import 'pages/swipe_actions_page.dart';
import 'pages/widget_lists_page.dart';

/// The first app version that ships an onboarding flow. Users who never
/// completed onboarding are treated as "before" this, so they see everything.
const String kAppOnboardingFirstVersion = '0.16.0';

/// Audience signals passed to an [OnboardingPageEntry.showWhen] predicate so it
/// can decide whether a page is relevant to *this* viewer.
class OnboardingAudience {
  /// `true` when the user has never finished onboarding (no
  /// `lastSeenOnboardingVersion`). Inverse of "upgrader".
  final bool isNewUser;

  /// `true` on Android (not web). Gates Android-only features like the
  /// home-screen widget.
  final bool isAndroid;

  /// `true` on desktop (macOS / Windows / Linux), where swipe gestures aren't
  /// universal — used to swap gesture explanations for click ones.
  final bool isDesktop;

  const OnboardingAudience({
    required this.isNewUser,
    required this.isAndroid,
    required this.isDesktop,
  });
}

/// Predicate that returns `true` when the page should appear for [audience].
typedef OnboardingShowWhen = bool Function(OnboardingAudience audience);

/// Shows the page only to returning users (upgraders) — "what's new" recaps.
bool onboardingUpgradersOnly(OnboardingAudience a) => !a.isNewUser;

/// Shows the page only on Android (e.g. pages advertising the home-screen
/// widget).
bool onboardingAndroidOnly(OnboardingAudience a) => a.isAndroid;

/// Shows the page only on desktop — for explanations that only make sense with
/// a mouse/keyboard (e.g. always-visible action buttons).
bool onboardingDesktopOnly(OnboardingAudience a) => a.isDesktop;

/// Shows the page only on non-desktop (mobile + web) — for touch-gesture
/// explanations (swipe, long-press).
bool onboardingMobileOnly(OnboardingAudience a) => !a.isDesktop;

/// One entry in [kAppOnboardingPages] — a page builder plus an optional
/// [showWhen] predicate. Compose conditions with `&&`.
class OnboardingPageEntry {
  final WidgetBuilder builder;

  /// When non-null, the page appears only if the predicate returns `true`.
  /// Null means "always show".
  final OnboardingShowWhen? showWhen;

  const OnboardingPageEntry({required this.builder, this.showWhen});
}

/// Map of app version → ordered page entries introduced in that version. A user
/// whose `lastSeenOnboardingVersion` is older than a key sees every page for
/// that key (subject to per-entry [OnboardingPageEntry.showWhen] filters).
///
/// Keys MUST be valid dotted versions parseable by [Version].
final Map<String, List<OnboardingPageEntry>> kAppOnboardingPages = {
  '0.16.0': [
    OnboardingPageEntry(
      builder: (_) => const ChecklistsRedesignIntroPage(),
      showWhen: onboardingUpgradersOnly,
    ),
    OnboardingPageEntry(
      builder: (_) => const ChecklistSelectorOnboardingPage(),
    ),
    OnboardingPageEntry(
      builder: (_) => const SwipeActionsOnboardingPage(),
      showWhen: onboardingMobileOnly,
    ),
    OnboardingPageEntry(
      builder: (_) => const QuickActionsOnboardingPage(),
      showWhen: onboardingDesktopOnly,
    ),
    OnboardingPageEntry(builder: (_) => const AddItemsOnboardingPage()),
    OnboardingPageEntry(
      builder: (_) => const ProgressHeroOnboardingPage(),
      showWhen: onboardingMobileOnly,
    ),
    OnboardingPageEntry(
      builder: (_) => const ProgressHeroDismissOnboardingPage(),
      showWhen: onboardingDesktopOnly,
    ),
    OnboardingPageEntry(
      builder: (_) => const WidgetListsOnboardingPage(),
      showWhen: onboardingAndroidOnly,
    ),
    OnboardingPageEntry(builder: (_) => const PinnedNotesOnboardingPage()),
  ],
  '0.18.0': [
    OnboardingPageEntry(builder: (_) => const AllListsOnboardingPage()),
    OnboardingPageEntry(builder: (_) => const BulkAddOnboardingPage()),
  ],
  '0.20.0': [
    OnboardingPageEntry(builder: (_) => const BulkSelectOnboardingPage()),
  ],
  '0.24.0': [
    OnboardingPageEntry(
      // Pitch camera scanning only where a camera is the point (mobile).
      builder: (_) => const BarcodeScanOnboardingPage(),
      showWhen: onboardingMobileOnly,
    ),
    OnboardingPageEntry(builder: (_) => const ItemPriceOnboardingPage()),
  ],
  '0.25.0': [
    OnboardingPageEntry(builder: (_) => const ShoppingModeOnboardingPage()),
  ],
  '0.28.0': [
    OnboardingPageEntry(builder: (_) => const CategoryScopeOnboardingPage()),
  ],
};

/// Versions offered by the dev-only "Show onboarding" picker — the
/// [kAppOnboardingPages] keys, newest first. Picking one previews that
/// version's what's-new (see [onboardingPreviewLastSeen]).
List<String> get kDevOnboardingPickableVersions {
  final keys = kAppOnboardingPages.keys.toList()
    ..sort((a, b) => Version.parse(b).compareTo(Version.parse(a)));
  return keys;
}

/// Dev-only: the `lastSeenOnboardingVersion` to persist so an onboarding
/// preview starts at [targetVersion]'s what's-new — the greatest page version
/// strictly below [targetVersion] (or a below-everything sentinel when it's the
/// earliest). [resolveOnboardingPages] shows everything newer than last-seen,
/// so seeding just below surfaces exactly what an upgrader to [targetVersion]
/// would see.
String onboardingPreviewLastSeen(String targetVersion) {
  final target = Version.parse(targetVersion);
  Version? predecessor;
  for (final key in kAppOnboardingPages.keys) {
    final v = Version.tryParse(key);
    if (v == null || v.compareTo(target) >= 0) continue;
    if (predecessor == null || v.compareTo(predecessor) > 0) predecessor = v;
  }
  return (predecessor ?? Version.parse('0.0.0')).toString();
}

/// The version to persist when the user finishes/skips onboarding for build
/// [appVersion]: the higher of [appVersion] and the newest [kAppOnboardingPages]
/// key. The `max` guards a platform quirk — Android can cache the previous
/// `flutter.versionName`, so `PackageInfo` may briefly report a stale version;
/// without the clamp, saving it would re-trigger the same onboarding next launch.
String onboardingMarkSeenVersion(String appVersion) {
  final appV = Version.tryParse(appVersion);
  Version? maxKeyV;
  for (final key in kAppOnboardingPages.keys) {
    final v = Version.tryParse(key);
    if (v == null) continue;
    if (maxKeyV == null || v.compareTo(maxKeyV) > 0) maxKeyV = v;
  }
  if (appV == null) return maxKeyV?.toString() ?? appVersion;
  if (maxKeyV == null) return appV.toString();
  return appV.compareTo(maxKeyV) >= 0 ? appV.toString() : maxKeyV.toString();
}

/// Returns `true` when [kAppOnboardingPages] has an entry newer than [lastSeen]
/// (or any entry when null). Cheap cold-start check for whether the first
/// capabilities fetch must block the initial route: server-backed pages always
/// show, but need fresh caps so the "requires Pantry vX" note is accurate
/// rather than derived from stale cached capabilities.
bool hasPendingOnboardingCandidates(String? lastSeen) {
  final lastSeenVersion = Version.tryParse(lastSeen);
  for (final key in kAppOnboardingPages.keys) {
    final v = Version.tryParse(key);
    if (v == null) continue;
    if (lastSeenVersion == null || v.compareTo(lastSeenVersion) > 0) {
      return true;
    }
  }
  return false;
}

/// Feature-page builders to show for a user whose last-seen version is
/// [lastSeen]: pages from every version newer than [lastSeen] (all when null),
/// oldest → newest, preserving each version's internal order. Entries whose
/// [OnboardingPageEntry.showWhen] returns `false` for the audience are dropped.
List<WidgetBuilder> resolveOnboardingPages(String? lastSeen) {
  final lastSeenVersion = Version.tryParse(lastSeen);
  final audience = OnboardingAudience(
    isNewUser: lastSeen == null,
    isAndroid: PlatformInfo.isAndroid,
    isDesktop: PlatformInfo.isDesktop,
  );
  final entries = kAppOnboardingPages.entries.toList();
  entries.sort((a, b) {
    final va = Version.parse(a.key);
    final vb = Version.parse(b.key);
    return va.compareTo(vb);
  });
  return [
    for (final entry in entries)
      if (lastSeenVersion == null ||
          Version.parse(entry.key).compareTo(lastSeenVersion) > 0)
        for (final page in entry.value)
          if (page.showWhen == null || page.showWhen!(audience)) page.builder,
  ];
}
