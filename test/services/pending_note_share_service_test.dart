import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/services/pending_note_share_service.dart';

void main() {
  final service = PendingNoteShareService.instance;

  setUp(() {
    // Drain anything left over from a previous test.
    service.takeForHouse(1);
    service.takeForHouse(2);
  });

  test('takeForHouse returns null when there is no pending share', () {
    expect(service.takeForHouse(1), isNull);
  });

  test('push then takeForHouse returns the share and clears it', () {
    service.push(const PendingNoteShare(houseId: 1, content: 'hello'));

    final taken = service.takeForHouse(1);
    expect(taken, isNotNull);
    expect(taken!.content, 'hello');

    // Once taken, the pending slot is empty.
    expect(service.pending, isNull);
    expect(service.takeForHouse(1), isNull);
  });

  test('takeForHouse for a different house returns null and keeps share', () {
    service.push(const PendingNoteShare(houseId: 1, content: 'hello'));

    expect(service.takeForHouse(2), isNull);
    expect(service.pending, isNotNull);
    expect(service.pending!.houseId, 1);
  });

  test('push notifies listeners', () {
    var notifications = 0;
    void listener() => notifications++;
    service.addListener(listener);

    service.push(const PendingNoteShare(houseId: 1, content: 'hi'));

    service.removeListener(listener);
    expect(notifications, 1);
  });
}
