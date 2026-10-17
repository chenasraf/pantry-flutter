import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/utils/log_masker.dart';

void main() {
  const masker = LogMasker(
    serverHost: 'nextcloud.example.nl',
    loginName: 'dani',
  );

  test('a URL keeps its scheme, port and path but not its host', () {
    expect(
      masker.mask('GET https://nextcloud.example.nl:8443/apps/pantry'),
      'GET https://<server>:8443/apps/pantry',
    );
    expect(
      masker.mask('-> https://other.example.com/login'),
      '-> https://<host>/login',
    );
  });

  test('credentials embedded in a URL go with its host', () {
    expect(
      masker.mask('https://dani:secret@nextcloud.example.nl/'),
      'https://<server>/',
    );
  });

  test('the server named bare, as in a failed lookup, is masked', () {
    expect(
      masker.mask("Failed host lookup: 'NextCloud.example.nl'"),
      "Failed host lookup: '<server>'",
    );
  });

  test('authorization headers and long tokens are redacted', () {
    expect(
      masker.mask('Authorization: Basic ZGFuaTpzZWNyZXQ='),
      'Authorization: Basic <redacted>',
    );
    expect(
      masker.mask('endpoint=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789'),
      'endpoint=<token>',
    );
  });

  test('the login, emails and IP addresses are masked', () {
    expect(masker.mask('signed in as dani'), 'signed in as <user>');
    expect(masker.mask('Daniel'), 'Daniel');
    expect(masker.mask('from a@b.example'), 'from <email>');
    expect(masker.mask('connect 192.168.1.20 failed'), 'connect <ip> failed');
  });

  test('a very short login is left alone rather than shredding words', () {
    const short = LogMasker(loginName: 'an');
    expect(short.mask('an answer'), 'an answer');
  });

  test('paths and ids survive', () {
    expect(
      masker.mask('POST /houses/1/lists/50/items 403 (120 ms)'),
      'POST /houses/1/lists/50/items 403 (120 ms)',
    );
  });
}
