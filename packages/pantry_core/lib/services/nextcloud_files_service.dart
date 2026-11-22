import 'dart:convert';
import 'dart:io' show HttpDate;

import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:xml/xml.dart';

/// One file or folder in the account's Nextcloud storage.
class RemoteFileEntry {
  /// Relative to the account's files root, with a leading slash and no
  /// trailing one: `/Documents/Notes`.
  final String path;
  final String name;
  final bool isFolder;

  /// Nextcloud's file id, which outlives renames and moves.
  final int? fileId;
  final String? contentType;
  final int? size;
  final DateTime? modifiedAt;

  /// Nextcloud's permission letters, e.g. `RGDNVCK`.
  final String permissions;

  const RemoteFileEntry({
    required this.path,
    required this.name,
    required this.isFolder,
    this.fileId,
    this.contentType,
    this.size,
    this.modifiedAt,
    this.permissions = '',
  });

  /// Whether a new file may be created inside this folder.
  bool get canCreateInside => isFolder && permissions.contains('C');

  /// The server turns down a note import over this size.
  static const maxImportBytes = 1024 * 1024;

  /// Whether the server would accept this file as a note: text it can read,
  /// no larger than [maxImportBytes].
  bool get isImportableAsNote {
    if (isFolder) return false;
    final type = contentType?.split(';').first.trim().toLowerCase();
    if (type == null) return false;
    if (!type.startsWith('text/') && type != 'application/json') return false;
    return (size ?? 0) <= maxImportBytes;
  }

  /// Whether the server would accept this file as an item image or photo.
  bool get isImage =>
      !isFolder &&
      fileId != null &&
      (contentType?.toLowerCase().startsWith('image/') ?? false);
}

/// A folder's own entry and what it holds.
class RemoteFolderListing {
  final RemoteFileEntry folder;
  final List<RemoteFileEntry> children;

  const RemoteFolderListing({required this.folder, required this.children});
}

/// Browses the account's Nextcloud files over WebDAV.
///
/// The note sync endpoints take a path relative to the account's files root,
/// which no OS file picker can produce: Android hands back opaque `content://`
/// URIs and iOS and macOS hand back local copies. Reading the server directly
/// with the app's own credential gives the same answer on every platform.
class NextcloudFilesService {
  NextcloudFilesService._();
  static final NextcloudFilesService instance = NextcloudFilesService._();

  static const _dav = ApiClient(basePath: '/remote.php/dav/files');
  static const _core = ApiClient(basePath: '/index.php/core');

  /// A thumbnail of one of the account's own files, from Nextcloud itself:
  /// Pantry's image preview only serves images already attached in a house.
  Uri imagePreviewUri(int fileId, {int size = 128}) => _core.buildUri(
    '/preview',
    {'fileId': '$fileId', 'x': '$size', 'y': '$size', 'a': '1'},
  );

  static const _propfindBody = '''
<?xml version="1.0"?>
<d:propfind xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns">
  <d:prop>
    <d:resourcetype/>
    <d:getcontenttype/>
    <d:getcontentlength/>
    <d:getlastmodified/>
    <oc:fileid/>
    <oc:permissions/>
  </d:prop>
</d:propfind>''';

  /// The contents of the folder at [path] (`/` for the root).
  Future<RemoteFolderListing> listFolder(String path) async {
    final userId = await AuthService.instance.accountUserId();
    final response = await _dav.send(
      'PROPFIND',
      davPath(userId, path),
      headers: {'Depth': '1', 'Content-Type': 'application/xml; charset=utf-8'},
      body: utf8.encode(_propfindBody),
    );
    return parsePropfind(utf8.decode(response.bodyBytes), userId: userId);
  }

  /// The request path below `/remote.php/dav/files` for [path] in [userId]'s
  /// storage, each segment encoded on its own so a `#`, `?` or space in a
  /// name stays part of it.
  static String davPath(String userId, String path) {
    final segments = [
      userId,
      ...path.split('/').where((s) => s.isNotEmpty),
    ].map(Uri.encodeComponent);
    return '/${segments.join('/')}/';
  }

  /// Reads a `Depth: 1` multistatus answer. The first response is the folder
  /// itself; the rest are its children, folders first and then by name.
  static RemoteFolderListing parsePropfind(
    String body, {
    required String userId,
  }) {
    final doc = XmlDocument.parse(body);
    final entries = [
      for (final response in doc.findAllElements('response', namespace: _d))
        ?_entry(response, userId),
    ];
    if (entries.isEmpty) {
      throw const FormatException('Empty WebDAV answer');
    }
    final children = entries.skip(1).toList()
      ..sort((a, b) {
        if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return RemoteFolderListing(folder: entries.first, children: children);
  }

  static const _d = 'DAV:';
  static const _oc = 'http://owncloud.org/ns';

  static RemoteFileEntry? _entry(XmlElement response, String userId) {
    final href = response.getElement('href', namespace: _d)?.innerText;
    if (href == null) return null;
    final path = _filesPath(href, userId);
    if (path == null) return null;

    // A propstat per status: the properties a file does not have (a folder's
    // content type, say) come back under a 404 and are not values.
    XmlElement? prop(String name, String ns) {
      for (final propstat in response.findElements('propstat', namespace: _d)) {
        final status = propstat.getElement('status', namespace: _d)?.innerText;
        if (status != null && !status.contains(' 200 ')) continue;
        final found = propstat
            .getElement('prop', namespace: _d)
            ?.getElement(name, namespace: ns);
        if (found != null) return found;
      }
      return null;
    }

    final isFolder =
        prop('resourcetype', _d)?.getElement('collection', namespace: _d) !=
        null;
    final type = prop('getcontenttype', _d)?.innerText.trim();
    final length = prop('getcontentlength', _d)?.innerText.trim();
    final modified = prop('getlastmodified', _d)?.innerText.trim();
    final fileId = prop('fileid', _oc)?.innerText.trim();
    return RemoteFileEntry(
      path: path,
      name: path == '/' ? '' : path.substring(path.lastIndexOf('/') + 1),
      isFolder: isFolder,
      fileId: fileId == null ? null : int.tryParse(fileId),
      contentType: type == null || type.isEmpty ? null : type,
      size: length == null ? null : int.tryParse(length),
      modifiedAt: modified == null ? null : _parseHttpDate(modified),
      permissions: prop('permissions', _oc)?.innerText.trim() ?? '',
    );
  }

  /// [href] relative to [userId]'s files root, decoded, or null for an href
  /// outside it.
  static String? _filesPath(String href, String userId) {
    final rawPath = Uri.tryParse(href)?.path ?? href;
    final segments = rawPath
        .split('/')
        .where((s) => s.isNotEmpty)
        .map(Uri.decodeComponent)
        .toList();
    // A server under a sub-path (`/nextcloud/remote.php/...`) puts more in
    // front, so find the marker rather than counting from the start.
    for (var i = 0; i + 3 < segments.length; i++) {
      if (segments[i] == 'remote.php' &&
          segments[i + 1] == 'dav' &&
          segments[i + 2] == 'files') {
        if (segments[i + 3] != userId) return null;
        return '/${segments.skip(i + 4).join('/')}';
      }
    }
    return null;
  }

  static DateTime? _parseHttpDate(String value) {
    try {
      return HttpDate.parse(value);
    } catch (_) {
      return null;
    }
  }
}
