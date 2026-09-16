import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// On-disk holding area for image bytes whose upload is waiting in the sync
/// queue, addressed by the uuid of the op that owes them.
///
/// The bytes cannot ride in the op body: the queue is a single JSON document
/// rewritten on every mutation, so a multi-megabyte photo would be re-encoded
/// and rewritten every time the user ticks something off. Nor can the op carry
/// the picker's own path — a camera capture lands in a cache directory the OS
/// reclaims, and the point of queueing is to survive until the connection comes
/// back, which may be days.
///
/// Blobs are named relative to the app documents directory rather than by
/// absolute path: an iOS container path changes across reinstalls and app
/// updates, and a stale absolute path would lose bytes that are still sitting
/// right there.
class PendingUploadStore {
  PendingUploadStore._();
  static final PendingUploadStore instance = PendingUploadStore._();

  static const _dirName = 'pending_uploads';

  Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_dirName');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Writes [bytes] for the op named [opUuid], replacing anything already
  /// stored under it.
  Future<void> save(String opUuid, List<int> bytes) async {
    final dir = await _dir();
    await File('${dir.path}/$opUuid').writeAsBytes(bytes, flush: true);
  }

  /// Where [opUuid]'s bytes live, whether or not they are there yet.
  ///
  /// Lets a widget draw a waiting upload straight off disk instead of holding
  /// the full-resolution capture in memory for as long as it waits — which, for
  /// a day out with no signal, is every photo of the day at once.
  Future<File> fileFor(String opUuid) async =>
      File('${(await _dir()).path}/$opUuid');

  /// [fileFor] for many blobs at once, resolving the directory a single time.
  Future<Map<String, File>> filesFor(Iterable<String> opUuids) async {
    final dir = await _dir();
    return {for (final uuid in opUuids) uuid: File('${dir.path}/$uuid')};
  }

  /// The bytes stored for [opUuid], or null when nothing is there.
  Future<Uint8List?> read(String opUuid) async {
    try {
      final file = File('${(await _dir()).path}/$opUuid');
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } catch (e) {
      debugPrint('[PendingUploadStore] Failed to read $opUuid: $e');
      return null;
    }
  }

  Future<void> delete(String opUuid) async {
    try {
      final file = File('${(await _dir()).path}/$opUuid');
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('[PendingUploadStore] Failed to delete $opUuid: $e');
    }
  }

  /// Deletes every blob [keep] does not name.
  ///
  /// This is the only reclamation path, and it runs at startup and at sign-out
  /// rather than the moment an op is dropped: a dropped upload's bytes are the
  /// user's last copy of a picture they can't take again, so they outlive the
  /// op long enough to be retried by hand. Anything still unclaimed by the next
  /// launch was nobody's, and a crash between writing bytes and enqueuing the
  /// op that would have owned them lands here too.
  Future<void> sweep(Set<String> keep) async {
    try {
      final dir = await _dir();
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (keep.contains(name)) continue;
        await entity.delete();
      }
    } catch (e) {
      debugPrint('[PendingUploadStore] Failed to sweep: $e');
    }
  }
}
