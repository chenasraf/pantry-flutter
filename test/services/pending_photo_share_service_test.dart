import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/services/pending_photo_share_service.dart';

void main() {
  final service = PendingPhotoShareService.instance;

  // Singleton — drain anything left from a previous test before each case so
  // tests are order-independent.
  setUp(() {
    service.takeForHouse(1);
    service.takeForHouse(2);
    service.takeForHouse(3);
  });

  test('takeForHouse returns empty list when nothing is queued', () {
    expect(service.takeForHouse(1), isEmpty);
  });

  test('enqueue makes the share available to the matching house', () {
    service.enqueue(
      const PendingPhotoShare(houseId: 1, folderId: null, paths: ['/a.jpg']),
    );

    final taken = service.takeForHouse(1);

    expect(taken, hasLength(1));
    expect(taken.first.houseId, 1);
    expect(taken.first.paths, ['/a.jpg']);
  });

  test('takeForHouse drains only entries for the requested house', () {
    service.enqueue(
      const PendingPhotoShare(houseId: 1, folderId: null, paths: ['/a.jpg']),
    );
    service.enqueue(
      const PendingPhotoShare(houseId: 2, folderId: 7, paths: ['/b.jpg']),
    );

    final fromHouse1 = service.takeForHouse(1);
    expect(fromHouse1, hasLength(1));
    expect(fromHouse1.first.houseId, 1);

    // House 2's entry is still there until claimed.
    final fromHouse2 = service.takeForHouse(2);
    expect(fromHouse2, hasLength(1));
    expect(fromHouse2.first.folderId, 7);
    expect(fromHouse2.first.paths, ['/b.jpg']);
  });

  test('takeForHouse removes consumed entries (idempotent on second call)', () {
    service.enqueue(
      const PendingPhotoShare(houseId: 1, folderId: null, paths: ['/a.jpg']),
    );

    expect(service.takeForHouse(1), hasLength(1));
    expect(service.takeForHouse(1), isEmpty);
  });

  test('enqueue notifies listeners', () {
    var notifications = 0;
    void listener() => notifications++;
    service.addListener(listener);

    service.enqueue(
      const PendingPhotoShare(houseId: 1, folderId: null, paths: ['/a.jpg']),
    );

    service.removeListener(listener);
    expect(notifications, 1);
  });
}
