import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/list_template.dart';

void main() {
  group('TemplateLists', () {
    test('reads learnItems from the server', () {
      final value = TemplateLists.fromJson({
        'everyList': false,
        'listIds': [3, 7],
        'learnItems': true,
      });
      expect(value.learnItems, isTrue);
      expect(value.listIds, [3, 7]);
    });

    test('treats a missing learnItems as off', () {
      final value = TemplateLists.fromJson({'everyList': true, 'listIds': []});
      expect(value.learnItems, isFalse);
      expect(value.everyList, isTrue);
    });

    test('sends learnItems with the attachments', () {
      const value = TemplateLists(listIds: [4], learnItems: true);
      expect(value.toJson(), {
        'everyList': false,
        'listIds': [4],
        'learnItems': true,
      });
    });

    test('copyWith keeps the fields it is not given', () {
      const value = TemplateLists(everyList: true, listIds: [1]);
      final changed = value.copyWith(learnItems: true);
      expect(changed.everyList, isTrue);
      expect(changed.listIds, [1]);
      expect(changed.learnItems, isTrue);
    });
  });
}
