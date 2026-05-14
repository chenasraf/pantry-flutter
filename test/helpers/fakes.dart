import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:pantry/models/house.dart';
import 'package:pantry/models/note.dart';
import 'package:pantry/models/notification.dart';
import 'package:pantry/models/photo.dart';
import 'package:pantry/views/home/home_controller.dart';
import 'package:pantry/views/notes/notes_controller.dart';
import 'package:pantry/views/notifications/notifications_controller.dart';
import 'package:pantry/views/photos/photo_board_controller.dart';

/// A fake [PhotoBoardController] that does not touch any services.
/// Subclasses [PhotoBoardController] and overrides everything that would
/// normally call the underlying [PhotoService].
class FakePhotoBoardController extends PhotoBoardController {
  FakePhotoBoardController({
    super.houseId = 1,
    String sortBy = 'custom',
    bool foldersFirst = true,
    List<UploadTask>? uploads,
  }) : _sortBy = sortBy,
       _foldersFirst = foldersFirst,
       _uploads = uploads ?? [];

  String _sortBy;
  @override
  String get sortBy => _sortBy;

  bool _foldersFirst;
  @override
  bool get foldersFirst => _foldersFirst;

  final List<UploadTask> _uploads;
  @override
  List<UploadTask> get uploads => _uploads;

  int retryCalls = 0;
  int dismissCalls = 0;
  String? lastSortBy;
  bool? lastFoldersFirst;
  UploadTask? lastRetried;
  UploadTask? lastDismissed;

  @override
  Future<void> load() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> setSortBy(String sort) async {
    _sortBy = sort;
    lastSortBy = sort;
    notifyListeners();
  }

  @override
  Future<void> setFoldersFirst(bool value) async {
    _foldersFirst = value;
    lastFoldersFirst = value;
    notifyListeners();
  }

  @override
  Future<void> retryUpload(UploadTask task) async {
    retryCalls++;
    lastRetried = task;
  }

  @override
  void dismissUpload(UploadTask task) {
    dismissCalls++;
    lastDismissed = task;
    _uploads.remove(task);
    notifyListeners();
  }

  @override
  Future<void> deletePhoto(Photo photo) async {}

  @override
  Future<void> uploadPhotos(List<XFile> files, {int? folderId}) async {}
}

/// A fake [NotesController] that does not touch any services.
class FakeNotesController extends NotesController {
  FakeNotesController({
    super.houseId = 1,
    String sortBy = 'custom',
    List<Note>? notes,
  }) : _sortBy = sortBy,
       _notes = notes ?? [];

  String _sortBy;
  @override
  String get sortBy => _sortBy;

  final List<Note> _notes;
  @override
  List<Note> get notes => _notes;

  String? lastSortBy;

  @override
  Future<void> load() async {}

  @override
  Future<void> setSortBy(String sort) async {
    _sortBy = sort;
    lastSortBy = sort;
    notifyListeners();
  }
}

/// A fake [HomeController] that does not touch any services.
class FakeHomeController extends HomeController {
  FakeHomeController({
    List<House>? houses,
    House? currentHouse,
    bool isLoading = false,
    String? error,
    bool serverAppMissing = false,
  }) : _houses = houses ?? [],
       _currentHouse = currentHouse,
       _isLoading = isLoading,
       _error = error,
       _serverAppMissing = serverAppMissing;

  final List<House> _houses;
  @override
  List<House> get houses => _houses;

  House? _currentHouse;
  @override
  House? get currentHouse => _currentHouse;

  final bool _isLoading;
  @override
  bool get isLoading => _isLoading;

  final String? _error;
  @override
  String? get error => _error;

  final bool _serverAppMissing;
  @override
  bool get serverAppMissing => _serverAppMissing;

  int loadCalls = 0;
  House? lastAdded;
  Exception? addError;

  @override
  Future<void> load() async {
    loadCalls++;
  }

  @override
  Future<House> addHouse({required String name, String? description}) async {
    if (addError != null) throw addError!;
    final house = House(
      id: _houses.length + 1,
      name: name,
      description: description,
      ownerUid: 'tester',
      role: 'owner',
      createdAt: 0,
      updatedAt: 0,
    );
    _houses.add(house);
    _currentHouse = house;
    lastAdded = house;
    notifyListeners();
    return house;
  }
}

/// A fake [NotificationsController] that does not touch any services.
class FakeNotificationsController extends NotificationsController {
  FakeNotificationsController({
    List<NcNotification>? notifications,
    bool isLoading = false,
    String? error,
  }) : _notifications = notifications ?? [],
       _isLoading = isLoading,
       _error = error;

  final List<NcNotification> _notifications;
  @override
  List<NcNotification> get notifications => _notifications;

  @override
  int get unreadCount => _notifications.length;

  final bool _isLoading;
  @override
  bool get isLoading => _isLoading;

  final String? _error;
  @override
  String? get error => _error;

  int loadCalls = 0;
  int refreshCalls = 0;
  int dismissCalls = 0;
  int dismissAllCalls = 0;
  NcNotification? lastDismissed;

  @override
  Future<void> load() async {
    loadCalls++;
  }

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }

  @override
  Future<void> dismiss(NcNotification notification) async {
    dismissCalls++;
    lastDismissed = notification;
    _notifications.removeWhere(
      (n) => n.notificationId == notification.notificationId,
    );
    notifyListeners();
  }

  @override
  Future<void> dismissAll() async {
    dismissAllCalls++;
    _notifications.clear();
    notifyListeners();
  }
}

/// Builds a fake [UploadTask] for tests.
UploadTask makeUploadTask({
  String fileName = 'photo.jpg',
  Uint8List? thumbnailBytes,
  double progress = 0.0,
  bool done = false,
  String? error,
}) {
  final task = UploadTask(
    fileName: fileName,
    thumbnailBytes: thumbnailBytes,
    mimeType: 'image/jpeg',
  );
  task.progress = progress;
  task.done = done;
  task.error = error;
  return task;
}
