import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/nextcloud_files_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';

String _response(
  String href, {
  bool folder = false,
  String? type,
  int? size,
  int? fileId,
  String permissions = 'RGDNVCK',
}) =>
    '''
<d:response>
  <d:href>$href</d:href>
  <d:propstat>
    <d:prop>
      <d:resourcetype>${folder ? '<d:collection/>' : ''}</d:resourcetype>
      ${type == null ? '' : '<d:getcontenttype>$type</d:getcontenttype>'}
      ${size == null ? '' : '<d:getcontentlength>$size</d:getcontentlength>'}
      ${fileId == null ? '' : '<oc:fileid>$fileId</oc:fileid>'}
      <d:getlastmodified>Sun, 22 Nov 2026 10:00:00 GMT</d:getlastmodified>
      <oc:permissions>$permissions</oc:permissions>
    </d:prop>
    <d:status>HTTP/1.1 200 OK</d:status>
  </d:propstat>
  ${folder ? '''
  <d:propstat>
    <d:prop><d:getcontenttype/><d:getcontentlength/></d:prop>
    <d:status>HTTP/1.1 404 Not Found</d:status>
  </d:propstat>''' : ''}
</d:response>''';

String _multistatus(List<String> responses) =>
    '''
<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns">
${responses.join('\n')}
</d:multistatus>''';

void main() {
  group('parsePropfind', () {
    test('skips the folder itself and sorts folders first, by name', () {
      final listing = NextcloudFilesService.parsePropfind(
        _multistatus([
          _response('/remote.php/dav/files/ada/', folder: true),
          _response(
            '/remote.php/dav/files/ada/zebra.md',
            type: 'text/markdown',
            size: 10,
          ),
          _response('/remote.php/dav/files/ada/Photos/', folder: true),
          _response(
            '/remote.php/dav/files/ada/apple.txt',
            type: 'text/plain',
            size: 5,
          ),
          _response('/remote.php/dav/files/ada/documents/', folder: true),
        ]),
        userId: 'ada',
      );

      expect(listing.folder.path, '/');
      expect(listing.folder.isFolder, isTrue);
      expect(listing.children.map((e) => e.name), [
        'documents',
        'Photos',
        'apple.txt',
        'zebra.md',
      ]);
      expect(listing.children.first.path, '/documents');
    });

    test('decodes names with spaces, #, ? and non-Latin scripts', () {
      final listing = NextcloudFilesService.parsePropfind(
        _multistatus([
          _response('/remote.php/dav/files/ada/My%20Notes/', folder: true),
          _response(
            '/remote.php/dav/files/ada/My%20Notes/a%23b%3Fc.md',
            type: 'text/markdown',
            size: 1,
          ),
          _response(
            '/remote.php/dav/files/ada/My%20Notes/%D7%A7%D7%A0%D7%99%D7%95%D7%AA.md',
            type: 'text/markdown',
            size: 1,
          ),
        ]),
        userId: 'ada',
      );

      expect(listing.folder.path, '/My Notes');
      expect(listing.folder.name, 'My Notes');
      expect(listing.children.map((e) => e.path), [
        '/My Notes/a#b?c.md',
        '/My Notes/קניות.md',
      ]);
    });

    test('reads a server installed under a sub-path', () {
      final listing = NextcloudFilesService.parsePropfind(
        _multistatus([
          _response(
            'https://cloud.example/nextcloud/remote.php/dav/files/ada/Docs/',
            folder: true,
          ),
        ]),
        userId: 'ada',
      );
      expect(listing.folder.path, '/Docs');
      expect(listing.children, isEmpty);
    });

    test('a folder without C cannot take a new file', () {
      final listing = NextcloudFilesService.parsePropfind(
        _multistatus([
          _response(
            '/remote.php/dav/files/ada/Shared/',
            folder: true,
            permissions: 'SRGDNV',
          ),
          _response('/remote.php/dav/files/ada/Shared/Inner/', folder: true),
        ]),
        userId: 'ada',
      );
      expect(listing.folder.canCreateInside, isFalse);
      expect(listing.children.single.canCreateInside, isTrue);
    });

    test('a folder\'s missing properties are not values', () {
      final listing = NextcloudFilesService.parsePropfind(
        _multistatus([_response('/remote.php/dav/files/ada/', folder: true)]),
        userId: 'ada',
      );
      expect(listing.folder.contentType, isNull);
      expect(listing.folder.size, isNull);
      expect(listing.folder.modifiedAt, DateTime.utc(2026, 11, 22, 10));
    });

    test('reads each file\'s Nextcloud id', () {
      final listing = NextcloudFilesService.parsePropfind(
        _multistatus([
          _response('/remote.php/dav/files/ada/', folder: true, fileId: 1),
          _response(
            '/remote.php/dav/files/ada/cat.jpg',
            type: 'image/jpeg',
            fileId: 42,
          ),
        ]),
        userId: 'ada',
      );
      expect(listing.folder.fileId, 1);
      expect(listing.children.single.fileId, 42);
    });
  });

  group('isImage', () {
    RemoteFileEntry file(String? type, {int? fileId = 7}) => RemoteFileEntry(
      path: '/f',
      name: 'f',
      isFolder: false,
      fileId: fileId,
      contentType: type,
    );

    test('takes any image type', () {
      expect(file('image/jpeg').isImage, isTrue);
      expect(file('IMAGE/PNG').isImage, isTrue);
      expect(file('image/avif').isImage, isTrue);
    });

    test('turns down other types, files without an id and folders', () {
      expect(file('video/x-matroska').isImage, isFalse);
      expect(file('text/plain').isImage, isFalse);
      expect(file(null).isImage, isFalse);
      expect(file('image/jpeg', fileId: null).isImage, isFalse);
      expect(
        const RemoteFileEntry(
          path: '/d',
          name: 'd',
          isFolder: true,
          fileId: 3,
        ).isImage,
        isFalse,
      );
    });
  });

  group('isImportableAsNote', () {
    RemoteFileEntry file(String? type, int size) => RemoteFileEntry(
      path: '/f',
      name: 'f',
      isFolder: false,
      contentType: type,
      size: size,
    );

    test('takes text and JSON up to 1 MiB', () {
      expect(file('text/markdown', 10).isImportableAsNote, isTrue);
      expect(file('text/plain; charset=utf-8', 10).isImportableAsNote, isTrue);
      expect(file('application/json', 10).isImportableAsNote, isTrue);
      expect(
        file('text/plain', RemoteFileEntry.maxImportBytes).isImportableAsNote,
        isTrue,
      );
    });

    test('turns down other types, larger files and folders', () {
      expect(file('image/png', 10).isImportableAsNote, isFalse);
      expect(file('application/pdf', 10).isImportableAsNote, isFalse);
      expect(file(null, 10).isImportableAsNote, isFalse);
      expect(
        file(
          'text/plain',
          RemoteFileEntry.maxImportBytes + 1,
        ).isImportableAsNote,
        isFalse,
      );
      expect(
        const RemoteFileEntry(
          path: '/d',
          name: 'd',
          isFolder: true,
        ).isImportableAsNote,
        isFalse,
      );
    });
  });

  group('listFolder', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    const secureStorage = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );

    setUpAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorage, (call) async => null);
    });

    setUp(() async {
      // An email login: the files root is named by the user id, which only
      // the server knows.
      await AuthService.instance.adoptCredentials(
        const NextcloudCredentials(
          serverUrl: 'https://cloud.example',
          loginName: 'ada@example.com',
          appPassword: 'secret',
        ),
      );
      SyncManager.instance.setOnline(true);
    });

    test('browses the user id\'s root, not the login name\'s', () async {
      final requests = <http.Request>[];
      final listing = await http.runWithClient(
        () => NextcloudFilesService.instance.listFolder('/My Notes'),
        () => MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/ocs/v2.php/cloud/user') {
            return http.Response(
              jsonEncode({
                'ocs': {
                  'data': {'id': 'ada7', 'display-name': 'Ada'},
                },
              }),
              200,
            );
          }
          return http.Response.bytes(
            utf8.encode(
              _multistatus([
                _response(
                  '/remote.php/dav/files/ada7/My%20Notes/',
                  folder: true,
                ),
              ]),
            ),
            207,
          );
        }),
      );

      final propfind = requests.last;
      expect(propfind.method, 'PROPFIND');
      expect(
        propfind.url.toString(),
        'https://cloud.example/remote.php/dav/files/ada7/My%20Notes/',
      );
      expect(propfind.headers['Depth'], '1');
      expect(listing.folder.path, '/My Notes');
      expect(AuthService.instance.credentials?.userId, 'ada7');
    });

    test('asks for the user id once and keeps it', () async {
      var userCalls = 0;
      Future<http.Response> handler(http.Request request) async {
        if (request.url.path == '/ocs/v2.php/cloud/user') {
          userCalls++;
          return http.Response(
            jsonEncode({
              'ocs': {
                'data': {'id': 'ada7'},
              },
            }),
            200,
          );
        }
        return http.Response(
          _multistatus([
            _response('/remote.php/dav/files/ada7/', folder: true),
          ]),
          207,
        );
      }

      await http.runWithClient(() async {
        await NextcloudFilesService.instance.listFolder('/');
        await NextcloudFilesService.instance.listFolder('/');
      }, () => MockClient(handler));
      expect(userCalls, 1);
    });

    test('a server error reaches the caller as an ApiException', () async {
      await AuthService.instance.adoptCredentials(
        const NextcloudCredentials(
          serverUrl: 'https://cloud.example',
          loginName: 'ada',
          appPassword: 'secret',
          userId: 'ada',
        ),
      );
      await expectLater(
        http.runWithClient(
          () => NextcloudFilesService.instance.listFolder('/Gone'),
          () => MockClient((_) async => http.Response('', 404)),
        ),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 404)),
      );
    });
  });

  group('davPath', () {
    test('encodes each segment on its own', () {
      expect(
        NextcloudFilesService.davPath('ada@example.com', '/a b/c#d/'),
        '/ada%40example.com/a%20b/c%23d/',
      );
      expect(NextcloudFilesService.davPath('ada', '/'), '/ada/');
    });
  });
}
