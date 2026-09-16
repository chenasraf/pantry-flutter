import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/views/onboarding/onboarding_pages.dart';
import 'package:pantry/views/onboarding/pages/add_items_page.dart';
import 'package:pantry/views/onboarding/pages/barcode_scan_page.dart';
import 'package:pantry/views/onboarding/pages/checklist_selector_page.dart';
import 'package:pantry/views/onboarding/pages/quick_actions_page.dart';
import 'package:pantry/views/onboarding/pages/shopping_mode_page.dart';
import 'package:pantry/views/onboarding/pages/swipe_actions_page.dart';
import 'package:pantry/views/onboarding/pages/watch_page.dart';

// A fresh install matches every version bucket at once, so the new-user tour is
// only as short as the showWhen filters make it. These tests pin the exact list
// per platform: adding a page without an audience guard lengthens the very first
// run of the app, and that should be a deliberate edit to this file.

const _androidPhone = OnboardingAudience(
  isNewUser: true,
  isAndroid: true,
  isDesktop: false,
);
const _iphone = OnboardingAudience(
  isNewUser: true,
  isAndroid: false,
  isDesktop: false,
);
const _desktop = OnboardingAudience(
  isNewUser: true,
  isAndroid: false,
  isDesktop: true,
);

/// The page types a new user walks through on [audience]'s platform.
///
/// Builds each page widget without pumping it — the pages animate, and the flow
/// under test is which ones get offered, not how they look.
List<Type> _tour(BuildContext context, OnboardingAudience audience) =>
    resolveOnboardingPages(
      null,
      audience: audience,
    ).map((build) => build(context).runtimeType).toList();

void main() {
  testWidgets('a new Android user walks the core tour and nothing else', (
    tester,
  ) async {
    final context = await _aContext(tester);

    expect(_tour(context, _androidPhone), [
      ChecklistSelectorOnboardingPage,
      SwipeActionsOnboardingPage,
      AddItemsOnboardingPage,
      BarcodeScanOnboardingPage,
      ShoppingModeOnboardingPage,
      // Guaranteed for new users: nothing in the app hints that a watch app
      // exists until you look for it.
      WatchOnboardingPage,
    ]);
  });

  testWidgets('a new iOS user gets the same tour without the watch page', (
    tester,
  ) async {
    final context = await _aContext(tester);

    expect(_tour(context, _iphone), [
      ChecklistSelectorOnboardingPage,
      SwipeActionsOnboardingPage,
      AddItemsOnboardingPage,
      BarcodeScanOnboardingPage,
      ShoppingModeOnboardingPage,
    ]);
  });

  testWidgets('a new desktop user gets clicks instead of swipes, no camera', (
    tester,
  ) async {
    final context = await _aContext(tester);

    expect(_tour(context, _desktop), [
      ChecklistSelectorOnboardingPage,
      QuickActionsOnboardingPage,
      AddItemsOnboardingPage,
      ShoppingModeOnboardingPage,
    ]);
  });

  test('every page still reaches an upgrader on some platform', () {
    // Guarding a page against new users must not strand it: each one has to
    // remain reachable as a what's-changed page for somebody.
    const upgraders = [
      OnboardingAudience(isNewUser: false, isAndroid: true, isDesktop: false),
      OnboardingAudience(isNewUser: false, isAndroid: false, isDesktop: false),
      OnboardingAudience(isNewUser: false, isAndroid: false, isDesktop: true),
    ];

    for (final bucket in kAppOnboardingPages.entries) {
      for (var i = 0; i < bucket.value.length; i++) {
        final showWhen = bucket.value[i].showWhen;
        expect(
          showWhen == null || upgraders.any(showWhen),
          isTrue,
          reason: 'page $i of ${bucket.key} reaches no upgrader anywhere',
        );
      }
    }
  });

  test('an upgrader sees more than a new user on the same device', () {
    final newUser = resolveOnboardingEntries(null, audience: _androidPhone);
    final upgrader = resolveOnboardingEntries(
      '0.15.0',
      audience: const OnboardingAudience(
        isNewUser: false,
        isAndroid: true,
        isDesktop: false,
      ),
    );

    expect(upgrader.length, greaterThan(newUser.length));
    // Everything a new user is shown is also part of the full catalogue.
    for (final entry in newUser) {
      expect(upgrader, contains(entry));
    }
  });
}

/// A live [BuildContext] to hand the page builders, from a widget tree that
/// holds nothing else.
Future<BuildContext> _aContext(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    Builder(
      builder: (context) {
        captured = context;
        return const SizedBox.shrink();
      },
    ),
  );
  return captured;
}
