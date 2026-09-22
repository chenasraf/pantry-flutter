import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/note.dart';
import 'package:pantry_core/services/server_version_service.dart';

Map<String, dynamic> _baseJson() => {
  'id': 5,
  'houseId': 1,
  'title': 'Weekly shop',
  'content': 'milk',
  'color': null,
  'createdBy': 'alice',
  'sortOrder': 0,
  'createdAt': 0,
  'updatedAt': 0,
};

void _seedSyncFeature({bool supported = true}) =>
    ServerVersionService.instance.debugSeed(
      features: {'note-file-sync': supported},
      featuresAuthoritative: true,
    );

void main() {
  tearDown(() => ServerVersionService.instance.debugSeed());

  group('Note.fromJson', () {
    test('reads the four sync fields', () {
      final note = Note.fromJson({
        ..._baseJson(),
        'syncFileId': 256,
        'syncOwnerUid': 'admin',
        'syncPath': '/Templates/Weekly shop.md',
        'syncAt': 1790116844,
      });
      expect(note.syncFileId, 256);
      expect(note.syncOwnerUid, 'admin');
      expect(note.syncPath, '/Templates/Weekly shop.md');
      expect(note.syncAt, 1790116844);
    });

    test('leaves them null when the server omits them', () {
      final note = Note.fromJson(_baseJson());
      expect(note.syncFileId, isNull);
      expect(note.syncOwnerUid, isNull);
      expect(note.syncPath, isNull);
      expect(note.syncAt, isNull);
    });
  });

  test('copyWith carries the binding through an edit', () {
    _seedSyncFeature();
    final note = Note.fromJson({
      ..._baseJson(),
      'syncFileId': 256,
      'syncOwnerUid': 'admin',
      'syncPath': '/Templates/Weekly shop.md',
      'syncAt': 1790116844,
    });
    final edited = note.copyWith(content: 'milk\nbread');
    expect(edited.isSynced, isTrue);
    expect(edited.syncFileId, 256);
    expect(edited.syncOwnerUid, 'admin');
    expect(edited.syncPath, '/Templates/Weekly shop.md');
    expect(edited.syncAt, 1790116844);
  });

  group('isSynced', () {
    test('is true for a bound note on a server that supports sync', () {
      _seedSyncFeature();
      final note = Note.fromJson({..._baseJson(), 'syncFileId': 256});
      expect(note.isSynced, isTrue);
    });

    test('is false without a binding', () {
      _seedSyncFeature();
      expect(Note.fromJson(_baseJson()).isSynced, isFalse);
    });

    test('is false on a server that does not support sync', () {
      _seedSyncFeature(supported: false);
      final note = Note.fromJson({..._baseJson(), 'syncFileId': 256});
      expect(note.isSynced, isFalse);
    });
  });

  group('syncDisplayPath', () {
    test('drops the leading slash', () {
      final note = Note.fromJson({
        ..._baseJson(),
        'syncFileId': 256,
        'syncPath': '/Templates/Weekly shop.md',
      });
      expect(note.syncDisplayPath, 'Templates/Weekly shop.md');
    });

    test('is null while the bound file is out of reach', () {
      final note = Note.fromJson({..._baseJson(), 'syncFileId': 256});
      expect(note.syncDisplayPath, isNull);
    });
  });
}
