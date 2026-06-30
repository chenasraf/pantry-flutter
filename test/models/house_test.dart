import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/models/house.dart';
import 'package:pantry/services/server_version_service.dart';

Map<String, dynamic> _baseJson() => {
  'id': 1,
  'name': 'Home',
  'description': null,
  'ownerUid': 'alice',
  'role': 'member',
  'createdAt': 0,
  'updatedAt': 0,
};

void main() {
  tearDown(() => ServerVersionService.instance.debugSeed());

  group('House.fromJson roles back-compat', () {
    test('omitted isAdmin/permissions default to non-admin, all-allowed', () {
      final house = House.fromJson(_baseJson());
      expect(house.isAdmin, isFalse);
      expect(house.permissions.canViewLists, isTrue);
      expect(house.permissions.canDeleteNotes, isTrue);
    });

    test('missing individual permission keys default to true', () {
      final house = House.fromJson({
        ..._baseJson(),
        'isAdmin': true,
        'permissions': {'canCreateLists': false, 'canCheckItems': false},
      });
      expect(house.isAdmin, isTrue);
      // Explicitly-false keys are honored...
      expect(house.permissions.canCreateLists, isFalse);
      expect(house.permissions.canCheckItems, isFalse);
      // ...absent keys fall back to allowed.
      expect(house.permissions.canViewLists, isTrue);
      expect(house.permissions.canDeletePhotos, isTrue);
    });
  });

  group('effectivePermissions', () {
    test(
      'ignores the permission map when the server lacks the roles feature',
      () {
        // No roles feature confirmed → gating off, everything allowed.
        ServerVersionService.instance.debugSeed(featuresAuthoritative: true);
        final house = House.fromJson({
          ..._baseJson(),
          'permissions': {'canViewLists': false, 'canAddItems': false},
        });
        expect(house.effectivePermissions.canViewLists, isTrue);
        expect(house.effectivePermissions.canAddItems, isTrue);
      },
    );

    test('honors the permission map when the server advertises roles', () {
      ServerVersionService.instance.debugSeed(
        features: {'roles': true},
        featuresAuthoritative: true,
      );
      final house = House.fromJson({
        ..._baseJson(),
        'permissions': {'canViewLists': false, 'canAddItems': false},
      });
      expect(house.effectivePermissions.canViewLists, isFalse);
      expect(house.effectivePermissions.canAddItems, isFalse);
      expect(house.effectivePermissions.canViewNotes, isTrue);
    });
  });

  test('toJson round-trips isAdmin and permissions', () {
    final house = House.fromJson({
      ..._baseJson(),
      'isAdmin': true,
      'permissions': {'canMovePhotos': false},
    });
    final restored = House.fromJson(house.toJson());
    expect(restored.isAdmin, isTrue);
    expect(restored.permissions.canMovePhotos, isFalse);
    expect(restored.permissions.canViewLists, isTrue);
  });
}
