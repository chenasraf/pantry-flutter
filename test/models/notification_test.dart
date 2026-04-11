import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/models/notification.dart';

void main() {
  group('NcNotification.fromJson', () {
    test('parses a minimal JSON payload', () {
      final n = NcNotification.fromJson({
        'notification_id': 42,
        'app': 'pantry',
        'user': 'alice',
        'subject': 'alice added an item',
        'datetime': '2026-04-11T12:00:00+00:00',
        'object_type': 'item',
        'object_id': '5',
      });

      expect(n.notificationId, 42);
      expect(n.app, 'pantry');
      expect(n.user, 'alice');
      expect(n.subject, 'alice added an item');
      expect(n.message, '');
      expect(n.datetime, '2026-04-11T12:00:00+00:00');
      expect(n.objectType, 'item');
      expect(n.objectId, '5');
      expect(n.icon, null);
      expect(n.link, null);
    });

    test('prefers parsed subject/message over rich templates', () {
      final n = NcNotification.fromJson({
        'notification_id': 1,
        'app': 'pantry',
        'user': 'u',
        'subject': 'Alice uploaded a photo in My Home',
        'subjectRich': '{user} uploaded a photo in {house}',
        'message': 'plain message',
        'messageRich': 'rich message template',
        'datetime': '2026-01-01T00:00:00+00:00',
        'object_type': 't',
        'object_id': '1',
      });

      expect(n.subject, 'Alice uploaded a photo in My Home');
      expect(n.message, 'plain message');
    });

    test('falls back to rich templates when parsed subject is missing', () {
      final n = NcNotification.fromJson({
        'notification_id': 1,
        'subjectRich': '{user} uploaded a photo',
        'messageRich': 'rich message',
      });

      expect(n.subject, '{user} uploaded a photo');
      expect(n.message, 'rich message');
    });

    test('falls back to empty strings when fields are missing', () {
      final n = NcNotification.fromJson({'notification_id': 1});

      expect(n.app, '');
      expect(n.user, '');
      expect(n.subject, '');
      expect(n.message, '');
      expect(n.datetime, '');
      expect(n.objectType, '');
      expect(n.objectId, '');
    });

    test('preserves optional icon and link', () {
      final n = NcNotification.fromJson({
        'notification_id': 1,
        'app': 'pantry',
        'user': 'u',
        'subject': 's',
        'datetime': '2026-01-01T00:00:00+00:00',
        'object_type': 't',
        'object_id': '1',
        'icon': 'https://example.com/icon.png',
        'link': 'https://example.com/link',
      });

      expect(n.icon, 'https://example.com/icon.png');
      expect(n.link, 'https://example.com/link');
    });
  });

  group('NcNotification.parsedDatetime', () {
    test('parses a valid ISO-8601 string', () {
      final n = NcNotification.fromJson({
        'notification_id': 1,
        'datetime': '2026-04-11T12:30:45+00:00',
      });

      final dt = n.parsedDatetime;
      expect(dt, isNotNull);
      expect(dt!.year, 2026);
      expect(dt.month, 4);
      expect(dt.day, 11);
    });

    test('returns null for unparseable strings', () {
      final n = NcNotification.fromJson({
        'notification_id': 1,
        'datetime': 'not a date',
      });

      expect(n.parsedDatetime, null);
    });

    test('returns null for empty datetime', () {
      final n = NcNotification.fromJson({'notification_id': 1});
      expect(n.parsedDatetime, null);
    });
  });
}
