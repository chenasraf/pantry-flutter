import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/shopping_presence_entry.dart';
import 'package:pantry_core/models/shopping_session.dart';

// Both DTOs parse with hard casts, so the fields a shared trip adds have to
// survive a server that never sends them — the trip still has exactly one
// shopper there, and that is what the fallback says.

void main() {
  Map<String, dynamic> sessionJson({List<String>? memberIds}) => {
    'id': 12,
    'houseId': 1,
    'userId': 'dana',
    'listIds': [4],
    'stores': [],
    'activeStoreId': null,
    'includeUnassigned': true,
    'isPrivate': false,
    'lastSeenAt': 0,
    'live': true,
    'createdAt': 0,
    'updatedAt': 0,
    'memberIds': ?memberIds,
  };

  Map<String, dynamic> presenceJson({
    int? sessionId,
    List<String>? memberIds,
  }) => {
    'userId': 'dana',
    'activeStoreId': 7,
    'lastSeenAt': 0,
    'sessionId': ?sessionId,
    'memberIds': ?memberIds,
  };

  group('ShoppingSession', () {
    test('reads the members of a shared trip, starter first', () {
      final session = ShoppingSession.fromJson(
        sessionJson(memberIds: ['dana', 'chen']),
      );

      expect(session.memberIds, ['dana', 'chen']);
      expect(session.othersThan('chen'), ['dana']);
      expect(session.isStartedBy('dana'), isTrue);
      expect(session.isStartedBy('chen'), isFalse);
    });

    test('falls back to the starter alone when the server sends no list', () {
      final session = ShoppingSession.fromJson(sessionJson());

      expect(session.memberIds, ['dana']);
      expect(session.othersThan('dana'), isEmpty);
    });

    test('round-trips its members through the cache', () {
      final session = ShoppingSession.fromJson(
        sessionJson(memberIds: ['dana', 'chen']),
      );

      expect(ShoppingSession.fromJson(session.toJson()).memberIds, [
        'dana',
        'chen',
      ]);
    });
  });

  group('ShoppingPresenceEntry', () {
    test('carries the trip and everyone on it', () {
      final entry = ShoppingPresenceEntry.fromJson(
        presenceJson(sessionId: 12, memberIds: ['dana', 'chen']),
      );

      expect(entry.sessionId, 12);
      expect(entry.memberIds, ['dana', 'chen']);
      expect(entry.includes('chen'), isTrue);
      expect(entry.includes('sam'), isFalse);
    });

    test('has no trip to join on a server that addresses only people', () {
      final entry = ShoppingPresenceEntry.fromJson(presenceJson());

      expect(entry.sessionId, isNull);
      expect(entry.memberIds, ['dana']);
    });
  });
}
