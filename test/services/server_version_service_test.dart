import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/version.dart';

void main() {
  const introduced = {'category-sort': '0.15.0', 'futureThing': '0.20.0'};

  group('comparePantryVersion — exact version known', () {
    final v = Version.parse('0.16.3');

    test('uses known version directly, ignores feature bounds', () {
      expect(
        comparePantryVersion(
          op: '>=',
          target: Version.parse('0.15.0'),
          known: v,
          features: const {'category-sort': false},
          featureIntroduced: introduced,
        ),
        isTrue,
      );
    });

    test('exact equality only works when version is known', () {
      expect(
        comparePantryVersion(
          op: '==',
          target: Version.parse('0.16.3'),
          known: v,
          features: const {},
          featureIntroduced: introduced,
        ),
        isTrue,
      );
    });
  });

  group('comparePantryVersion — inferred from feature support', () {
    // Server has `category-sort` (added in 0.15.0) but no other feature data,
    // and no exact version. We know server >= 0.15.0.
    final supportsSort = const {'category-sort': true};

    test('>= 0.15.0 → true (lower bound satisfies target)', () {
      expect(
        comparePantryVersion(
          op: '>=',
          target: Version.parse('0.15.0'),
          known: null,
          features: supportsSort,
          featureIntroduced: introduced,
        ),
        isTrue,
      );
    });

    test('>= 0.14.0 → true (lower bound exceeds target)', () {
      expect(
        comparePantryVersion(
          op: '>=',
          target: Version.parse('0.14.0'),
          known: null,
          features: supportsSort,
          featureIntroduced: introduced,
        ),
        isTrue,
      );
    });

    test('>= 0.16.0 → false (can\'t prove server is that new)', () {
      expect(
        comparePantryVersion(
          op: '>=',
          target: Version.parse('0.16.0'),
          known: null,
          features: supportsSort,
          featureIntroduced: introduced,
        ),
        isFalse,
      );
    });

    test('< 0.15.0 with category-sort=true → false', () {
      expect(
        comparePantryVersion(
          op: '<',
          target: Version.parse('0.15.0'),
          known: null,
          features: supportsSort,
          featureIntroduced: introduced,
        ),
        isFalse,
      );
    });
  });

  group('comparePantryVersion — inferred from feature absence', () {
    // Server probe found category-sort missing → server < 0.15.0.
    final missingSort = const {'category-sort': false};

    test('< 0.15.0 → true (upper bound proves it)', () {
      expect(
        comparePantryVersion(
          op: '<',
          target: Version.parse('0.15.0'),
          known: null,
          features: missingSort,
          featureIntroduced: introduced,
        ),
        isTrue,
      );
    });

    test('<= 0.15.0 → true (server < 0.15 implies <= 0.15)', () {
      expect(
        comparePantryVersion(
          op: '<=',
          target: Version.parse('0.15.0'),
          known: null,
          features: missingSort,
          featureIntroduced: introduced,
        ),
        isTrue,
      );
    });

    test('< 0.14.0 → false (could be exactly 0.14)', () {
      expect(
        comparePantryVersion(
          op: '<',
          target: Version.parse('0.14.0'),
          known: null,
          features: missingSort,
          featureIntroduced: introduced,
        ),
        isFalse,
      );
    });

    test('>= 0.15.0 → false', () {
      expect(
        comparePantryVersion(
          op: '>=',
          target: Version.parse('0.15.0'),
          known: null,
          features: missingSort,
          featureIntroduced: introduced,
        ),
        isFalse,
      );
    });
  });

  group('comparePantryVersion — multiple features tighten the range', () {
    // Server has category-sort (>= 0.15) but not futureThing (< 0.20).
    // Server ∈ [0.15, 0.20).
    final partial = const {'category-sort': true, 'futureThing': false};

    test('>= 0.15.0 → true', () {
      expect(
        comparePantryVersion(
          op: '>=',
          target: Version.parse('0.15.0'),
          known: null,
          features: partial,
          featureIntroduced: introduced,
        ),
        isTrue,
      );
    });

    test('< 0.20.0 → true', () {
      expect(
        comparePantryVersion(
          op: '<',
          target: Version.parse('0.20.0'),
          known: null,
          features: partial,
          featureIntroduced: introduced,
        ),
        isTrue,
      );
    });

    test('exact equality still false — bounds can\'t prove a single value', () {
      expect(
        comparePantryVersion(
          op: '==',
          target: Version.parse('0.15.0'),
          known: null,
          features: partial,
          featureIntroduced: introduced,
        ),
        isFalse,
      );
    });
  });

  group('comparePantryVersion — nothing known', () {
    test('every operator returns false — fail closed', () {
      for (final op in ['>=', '<=', '>', '<', '==', '!=']) {
        expect(
          comparePantryVersion(
            op: op,
            target: Version.parse('0.15.0'),
            known: null,
            features: const {},
            featureIntroduced: introduced,
          ),
          isFalse,
          reason: op,
        );
      }
    });
  });

  group('ServerFeature', () {
    tearDown(() => ServerVersionService.instance.clear());

    test('opens on the release that shipped the feature', () {
      ServerVersionService.instance.debugSeed(
        pantryVersion: Version.parse('0.22.0'),
      );
      expect(ServerFeature.stores, isTrue);
      expect(ServerFeature.itemArchive, isTrue);
    });

    test('stays closed on the release before it', () {
      ServerVersionService.instance.debugSeed(
        pantryVersion: Version.parse('0.21.0'),
      );
      expect(ServerFeature.stores, isFalse);
    });

    test('stays closed when the version is unknown', () {
      expect(ServerFeature.checklistColor, isFalse);
    });

    test('probe-confirmed pre-0.16 features open without a version', () {
      ServerVersionService.instance.debugSeed(
        features: {'category-sort': true},
      );
      expect(ServerFeature.categorySort, isTrue);
      expect(ServerFeature.itemAuthors, isTrue);
      expect(ServerFeature.checklistColor, isFalse);
    });
  });

  group('ServerVersionService.observeHousePrefs', () {
    tearDown(() => ServerVersionService.instance.clear());

    bool atLeast015() =>
        ServerVersionService.instance.isServerPantryVersion('>=', '0.15.0');

    test('bounds the version at 0.15.0 when showAddedBy is present', () {
      ServerVersionService.instance.observeHousePrefs({
        'showAddedBy': false,
        'categorySort': 'custom',
      });
      expect(atLeast015(), isTrue);
    });

    test('bounds the version below 0.15.0 when showAddedBy is missing', () {
      ServerVersionService.instance.observeHousePrefs({
        'categorySort': 'custom',
      });
      expect(atLeast015(), isFalse);
      expect(
        ServerVersionService.instance.isServerPantryVersion('<', '0.15.0'),
        isTrue,
      );
    });

    test('is a no-op when the server reports its version', () {
      ServerVersionService.instance.debugSeed(
        pantryVersion: Version.parse('0.30.0'),
      );
      ServerVersionService.instance.observeHousePrefs(const {});
      expect(atLeast015(), isTrue);
    });

    test('does not overwrite a previous observation', () {
      ServerVersionService.instance.observeHousePrefs({'showAddedBy': true});
      ServerVersionService.instance.observeHousePrefs(const {});
      expect(atLeast015(), isTrue);
    });
  });
}
