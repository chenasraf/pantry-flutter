import 'package:flutter/foundation.dart';

/// A pending photo upload originating from an OS share intent. Held in a
/// queue until the [PhotoBoardController] for the same house picks it up.
class PendingPhotoShare {
  final int houseId;
  final int? folderId;
  final List<String> paths;

  const PendingPhotoShare({
    required this.houseId,
    required this.folderId,
    required this.paths,
  });
}

/// Cross-screen queue of pending photo uploads from share intents. The
/// share-router enqueues entries here, then asks the home view to switch
/// to the correct house + photo tab. The [PhotoBoardController] for that
/// house listens and consumes its matching entries.
class PendingPhotoShareService extends ChangeNotifier {
  PendingPhotoShareService._();
  static final PendingPhotoShareService instance = PendingPhotoShareService._();

  final List<PendingPhotoShare> _queue = [];

  void enqueue(PendingPhotoShare share) {
    _queue.add(share);
    notifyListeners();
  }

  /// Remove and return all pending uploads belonging to [houseId].
  List<PendingPhotoShare> takeForHouse(int houseId) {
    final taken = _queue.where((s) => s.houseId == houseId).toList();
    if (taken.isNotEmpty) {
      _queue.removeWhere((s) => s.houseId == houseId);
    }
    return taken;
  }
}
