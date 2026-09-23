import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/photo.dart';

import '../helpers/fakes.dart';

void main() {
  /// `createdAt` deliberately runs opposite to the list order, so a preview
  /// that sorts by upload time instead of following the board is visible in
  /// the result rather than hidden behind agreeing orders.
  Photo photo(int id, {int? folderId, required int createdAt}) => Photo(
    id: id,
    houseId: 1,
    folderId: folderId,
    fileId: id,
    uploadedBy: 'someone',
    sortOrder: id,
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  test('the preview takes the folder\'s photos in the board\'s order', () {
    final controller = FakePhotoBoardController(
      photos: [
        photo(1, folderId: 7, createdAt: 100),
        photo(2, folderId: 7, createdAt: 900),
        photo(3, folderId: 7, createdAt: 500),
        photo(4, folderId: 7, createdAt: 700),
      ],
    );
    addTearDown(controller.dispose);

    expect(
      controller.folderPreviewPhotos(7).map((p) => p.id),
      [1, 2, 3],
      reason: 'the first three of the folder, not the three newest',
    );
  });

  test('the preview leads with what the folder leads with', () {
    final controller = FakePhotoBoardController(
      photos: [
        photo(1, folderId: 7, createdAt: 100),
        photo(2, folderId: 7, createdAt: 900),
      ],
    );
    addTearDown(controller.dispose);

    controller.enterFolder(7);
    expect(
      controller.folderPreviewPhotos(7).first.id,
      controller.visiblePhotos.first.id,
    );
  });

  test('photos outside the folder are left out', () {
    final controller = FakePhotoBoardController(
      photos: [
        photo(1, createdAt: 100),
        photo(2, folderId: 7, createdAt: 200),
        photo(3, folderId: 8, createdAt: 300),
        photo(4, folderId: 7, createdAt: 400),
      ],
    );
    addTearDown(controller.dispose);

    expect(controller.folderPreviewPhotos(7).map((p) => p.id), [2, 4]);
  });

  test('a folder with more than three photos is capped at three', () {
    final controller = FakePhotoBoardController(
      photos: [
        for (var i = 1; i <= 6; i++) photo(i, folderId: 7, createdAt: i * 10),
      ],
    );
    addTearDown(controller.dispose);

    expect(controller.folderPreviewPhotos(7), hasLength(3));
  });
}
