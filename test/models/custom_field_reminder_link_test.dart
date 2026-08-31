import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/models/notification.dart';
import 'package:pantry/services/deep_link_service.dart';

void main() {
  group('cf_reminder notification deep link', () {
    NcNotification reminder({String? link}) => NcNotification(
      notificationId: 1,
      app: 'pantry',
      user: 'casraf',
      subject: 'Milk — Expiry: Sep 7',
      message: '',
      datetime: '',
      objectType: 'cf_reminder',
      objectId: '56:6',
      link: link,
    );

    test('targets the checklists tab', () {
      expect(reminder().target, NotificationTarget.checklists);
    });

    test('parses house/list/item ids from the link', () {
      final target = reminder(
        link:
            'https://nc.example/index.php/apps/pantry/houses/12/lists/34'
            '?item=56',
      ).itemLinkTarget;

      expect(target, isNotNull);
      expect(target!.houseId, 12);
      expect(target.listId, 34);
      expect(target.itemId, 56);
    });

    test('yields no target when the link is missing the item query', () {
      final target = reminder(
        link: 'https://nc.example/apps/pantry/houses/12/lists/34',
      ).itemLinkTarget;
      expect(target, isNull);
    });
  });

  group('DeepLink item payload', () {
    test('round-trips list + item ids', () {
      const link = DeepLink(tabIndex: 0, houseId: 12, listId: 34, itemId: 56);
      final decoded = DeepLink.decode(link.encode());

      expect(decoded, isNotNull);
      expect(decoded!.houseId, 12);
      expect(decoded.listId, 34);
      expect(decoded.itemId, 56);
    });

    test('decodes the older two-field (tab:house) payload', () {
      final decoded = DeepLink.decode('0:12');
      expect(decoded, isNotNull);
      expect(decoded!.houseId, 12);
      expect(decoded.listId, isNull);
      expect(decoded.itemId, isNull);
    });
  });
}
