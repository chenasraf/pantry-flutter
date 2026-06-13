import 'package:flutter/material.dart';

import 'package:pantry/utils/version.dart';
import 'pages/add_items_page.dart';
import 'pages/checklist_selector_page.dart';
import 'pages/checklists_redesign_intro_page.dart';
import 'pages/progress_hero_page.dart';
import 'pages/swipe_actions_page.dart';

/// The first app version that ships an onboarding flow. New users that haven't
/// completed any onboarding are treated as "before" this version, so they see
/// the full sequence (welcome + every feature page in [kAppOnboardingPages]).
const String kAppOnboardingFirstVersion = '0.16.0';

/// One entry in [kAppOnboardingPages]. Carries a builder plus flags that
/// control which audience the page is relevant to — e.g. a "what's new"
/// section header is only meaningful for upgraders, not first-time users.
class OnboardingPageEntry {
  final WidgetBuilder builder;

  /// When `true`, the page is skipped for brand-new users (those whose
  /// `lastSeenOnboardingVersion` is null) and only shown to returning users
  /// upgrading from a previous version. Use this for "what's new" recap
  /// pages that don't make sense to someone who has never used the app.
  final bool updateOnly;

  const OnboardingPageEntry({required this.builder, this.updateOnly = false});
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
      updateOnly: true,
    ),
    OnboardingPageEntry(
      builder: (_) => const ChecklistSelectorOnboardingPage(),
    ),
    OnboardingPageEntry(builder: (_) => const SwipeActionsOnboardingPage()),
    OnboardingPageEntry(builder: (_) => const AddItemsOnboardingPage()),
    OnboardingPageEntry(builder: (_) => const ProgressHeroOnboardingPage()),
  ],
};

/// Versions available for the dev-only "Show onboarding" picker — must be
/// historical (i.e. strictly older than [kAppOnboardingFirstVersion] OR a
/// known prior key in [kAppOnboardingPages]). The list is in descending order
/// so the newest option appears first.
const List<String> kDevOnboardingPickableVersions = ['0.15.0'];

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

/// Resolve which feature-page builders should appear in onboarding for a user
/// whose last-seen onboarding version is [lastSeen]. Returns pages from every
/// version newer than [lastSeen] (or all of them when [lastSeen] is null),
/// preserving each version's internal order, sorted oldest → newest. Entries
/// marked [OnboardingPageEntry.updateOnly] are excluded when [lastSeen] is
/// null (brand-new user).
List<WidgetBuilder> resolveOnboardingPages(String? lastSeen) {
  final lastSeenVersion = Version.tryParse(lastSeen);
  final isNewUser = lastSeen == null;
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
          if (!(isNewUser && page.updateOnly)) page.builder,
  ];
}
