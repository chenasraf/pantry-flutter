import 'package:flutter/material.dart';

import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/utils/version.dart';
import 'pages/add_items_page.dart';
import 'pages/all_lists_page.dart';
import 'pages/bulk_add_page.dart';
import 'pages/checklist_selector_page.dart';
import 'pages/checklists_redesign_intro_page.dart';
import 'pages/pinned_lists_page.dart';
import 'pages/pinned_notes_page.dart';
import 'pages/progress_hero_dismiss_page.dart';
import 'pages/progress_hero_page.dart';
import 'pages/quick_actions_page.dart';
import 'pages/swipe_actions_page.dart';

/// The first app version that ships an onboarding flow. New users that haven't
/// completed any onboarding are treated as "before" this version, so they see
/// the full sequence (welcome + every feature page in [kAppOnboardingPages]).
const String kAppOnboardingFirstVersion = '0.16.0';

/// Context passed to an [OnboardingPageEntry.showWhen] predicate so it can
/// decide whether the page is relevant to *this* viewer. Bundles every
/// audience signal we currently filter on (and is the place to add more —
/// locale, paid tier, feature flag, …).
class OnboardingAudience {
  /// `true` when the user has never finished any onboarding before — i.e.
  /// their `lastSeenOnboardingVersion` is null. Inverse of "upgrader".
  final bool isNewUser;

  /// `true` when the running platform is Android (and not web). Use to gate
  /// features that only exist on Android, e.g. the home-screen widget.
  final bool isAndroid;

  /// `true` when the running platform is a desktop OS (macOS / Windows /
  /// Linux), where horizontal-swipe gestures aren't universally available.
  /// Use to swap interaction explanations (e.g. "swipe to reveal" → "tap
  /// the action").
  final bool isDesktop;

  const OnboardingAudience({
    required this.isNewUser,
    required this.isAndroid,
    required this.isDesktop,
  });
}

/// Predicate that returns `true` when the page should appear for [audience].
typedef OnboardingShowWhen = bool Function(OnboardingAudience audience);

/// Shows the page only to returning users — those upgrading from an older
/// version. "What's new" recaps live behind this.
bool onboardingUpgradersOnly(OnboardingAudience a) => !a.isNewUser;

/// Shows the page only on Android. The home-screen widget is Android-only,
/// so any page that advertises it should gate on this.
bool onboardingAndroidOnly(OnboardingAudience a) => a.isAndroid;

/// Shows the page only on desktop platforms. Use for explanations that only
/// make sense to a mouse/keyboard user (e.g. always-visible action buttons).
bool onboardingDesktopOnly(OnboardingAudience a) => a.isDesktop;

/// Shows the page only on non-desktop platforms (mobile + web). Use for
/// explanations of touch gestures (swipe, long-press) that don't translate.
bool onboardingMobileOnly(OnboardingAudience a) => !a.isDesktop;

/// One entry in [kAppOnboardingPages]. Carries the page builder plus an
/// optional [showWhen] predicate that decides whether *this* viewer sees it.
/// Compose multiple conditions inline with `&&` — e.g.
/// `showWhen: (a) => onboardingAndroidOnly(a) && onboardingUpgradersOnly(a)`.
class OnboardingPageEntry {
  final WidgetBuilder builder;

  /// When non-null, the page only appears if the predicate returns `true`
  /// for the current audience. A null predicate means "always show".
  final OnboardingShowWhen? showWhen;

  const OnboardingPageEntry({required this.builder, this.showWhen});
}

/// Map of app version → ordered list of page entries introduced in that
/// version. When a user opens a build whose `lastSeenOnboardingVersion` is
/// older than a key here, they will see every page for that key (subject to
/// per-entry filters like [OnboardingPageEntry.updateOnly]).
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
      builder: (_) => const PinnedListsOnboardingPage(),
      showWhen: onboardingAndroidOnly,
    ),
    OnboardingPageEntry(builder: (_) => const PinnedNotesOnboardingPage()),
  ],
  '0.18.0': [
    OnboardingPageEntry(
      builder: (_) => const AllListsOnboardingPage(),
      showWhen: (_) => hasFeature('checklist-all-view'),
    ),
    OnboardingPageEntry(builder: (_) => const BulkAddOnboardingPage()),
  ],
};

/// Versions available for the dev-only "Show onboarding" picker — must be
/// historical (i.e. strictly older than [kAppOnboardingFirstVersion] OR a
/// known prior key in [kAppOnboardingPages]). The list is in descending order
/// so the newest option appears first.
const List<String> kDevOnboardingPickableVersions = [
  '0.17.0',
  '0.16.0',
  '0.15.0',
];

/// The version string to persist when the user finishes/skips onboarding for
/// build [appVersion]. Returns whichever is higher between [appVersion] and
/// the newest key in [kAppOnboardingPages]. The defensive `max` matters
/// because some platforms (notably Android's `local.properties` /
/// `flutter.versionName`) cache the previous version between builds, so
/// `PackageInfo` can briefly report a stale version — without the clamp,
/// saving that stale value would re-trigger the same onboarding on next
/// launch.
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

/// Returns `true` when [kAppOnboardingPages] has at least one version entry
/// strictly newer than [lastSeen] (or any entry at all when [lastSeen] is
/// null). Cheap, feature-independent check used at cold start to decide
/// whether the first capabilities fetch needs to block the initial route —
/// without it, feature-gated pages (e.g. `checklist-all-view`) can be filtered
/// out using stale cached capabilities and skipped permanently once the user
/// completes the rest of the flow.
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

/// Resolve which feature-page builders should appear in onboarding for a user
/// whose last-seen onboarding version is [lastSeen]. Returns pages from every
/// version newer than [lastSeen] (or all of them when [lastSeen] is null),
/// preserving each version's internal order, sorted oldest → newest. Entries
/// whose [OnboardingPageEntry.showWhen] predicate returns `false` for the
/// current audience are filtered out.
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
