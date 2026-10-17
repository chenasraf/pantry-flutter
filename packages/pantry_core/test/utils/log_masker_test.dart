import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/utils/log_masker.dart';

void main() {
  const masker = LogMasker(serverHost: 'cloud.example.com', loginName: 'ada');

  test('a URL keeps its scheme, port and path but not its host', () {
    expect(
      masker.mask('GET https://cloud.example.com:8443/apps/pantry'),
      'GET https://<server>:8443/apps/pantry',
    );
    expect(
      masker.mask('-> https://other.example.com/login'),
      '-> https://<host>/login',
    );
  });

  test('credentials embedded in a URL go with its host', () {
    expect(
      masker.mask('https://ada:secret@cloud.example.com/'),
      'https://<server>/',
    );
  });

  test('the server named bare, as in a failed lookup, is masked', () {
    expect(
      masker.mask("Failed host lookup: 'Cloud.Example.com'"),
      "Failed host lookup: '<server>'",
    );
  });

  test('authorization headers and long tokens are redacted', () {
    expect(
      masker.mask('Authorization: Basic YWRhOnNlY3JldA=='),
      'Authorization: Basic <redacted>',
    );
    expect(
      masker.mask('endpoint=AbCdEfGhIjKlMnOpQrStUvWxYz0123456789'),
      'endpoint=<token>',
    );
  });

  test('the login, emails and IP addresses are masked', () {
    expect(masker.mask('signed in as ada'), 'signed in as <user>');
    expect(masker.mask('Adams'), 'Adams');
    expect(masker.mask('from a@b.example'), 'from <email>');
    expect(masker.mask('connect 192.168.1.20 failed'), 'connect <ip> failed');
  });

  test('a very short login is left alone rather than shredding words', () {
    const short = LogMasker(loginName: 'an');
    expect(short.mask('an answer'), 'an answer');
  });

  test('paths and ids survive, however long', () {
    expect(
      masker.mask('POST /houses/1/lists/50/items 403 (120 ms)'),
      'POST /houses/1/lists/50/items 403 (120 ms)',
    );
    const long = 'PATCH /houses/1/shopping/sessions/5/items/60/billed 200';
    expect(masker.mask(long), long);
    expect(
      masker.mask('uri=https://cloud.example.com/ocs/v2.php/apps/pantry/api'),
      'uri=https://<server>/ocs/v2.php/apps/pantry/api',
    );
  });

  test('a hand-made app password is redacted', () {
    expect(
      masker.mask('password Ab3dE-fGh1J-kLm2N-oPq3R-sTu4V'),
      'password <token>',
    );
  });
}
