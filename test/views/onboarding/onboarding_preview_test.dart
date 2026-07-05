import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/views/onboarding/onboarding_pages.dart';

// The dev "Show onboarding" picker lists the actual page versions, and picking
// one previews *that* version's what's-new. That relies on
// onboardingPreviewLastSeen seeding last-seen just below the picked version.

void main() {
  test('pickable versions are the page keys, newest first', () {
    final versions = kDevOnboardingPickableVersions;
    expect(versions, isNotEmpty);
    // Every offered version is a real page bucket.
    for (final v in versions) {
      expect(kAppOnboardingPages.containsKey(v), isTrue);
    }
    // Same set as the page keys, and sorted descending.
    expect(versions.toSet(), kAppOnboardingPages.keys.toSet());
    final sortedDesc = [...versions]
      ..sort((a, b) => b.compareTo(a)); // string sort is fine for these keys
    expect(versions, sortedDesc);
  });

  group('onboardingPreviewLastSeen', () {
    test('maps a version to the greatest page version below it', () {
      // Given the current buckets 0.16.0 / 0.18.0 / 0.20.0:
      expect(onboardingPreviewLastSeen('0.20.0'), '0.18.0');
      expect(onboardingPreviewLastSeen('0.18.0'), '0.16.0');
    });

    test('falls back to a below-everything sentinel for the earliest', () {
      expect(onboardingPreviewLastSeen('0.16.0'), '0.0.0');
    });
  });
}
