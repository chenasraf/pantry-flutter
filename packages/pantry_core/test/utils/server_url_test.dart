import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/utils/server_url.dart';

/// What a typed server address means.
///
/// Two surfaces now take one from a human, and the address is what a
/// certificate pin is keyed on — so a host the two disagree about is a pin one
/// of them cannot match.
void main() {
  test('assumes https where no scheme was typed', () {
    expect(normalizeServerUrl('cloud.example'), 'https://cloud.example');
  });

  test('leaves a scheme the user typed alone, http included', () {
    expect(normalizeServerUrl('http://cloud.example'), 'http://cloud.example');
    expect(
      normalizeServerUrl('https://cloud.example'),
      'https://cloud.example',
    );
  });

  test('drops surrounding space and one trailing slash', () {
    expect(normalizeServerUrl('  cloud.example/  '), 'https://cloud.example');
  });

  test('keeps a path, which self-hosters put Nextcloud under', () {
    expect(
      normalizeServerUrl('cloud.example/nextcloud'),
      'https://cloud.example/nextcloud',
    );
  });

  /// Which addresses a Bluetooth-linked watch cannot reach, whatever the link
  /// says about itself.
  group('isPrivateHost', () {
    test('the three private IPv4 ranges, and their public neighbours', () {
      expect(isPrivateHost('10.0.0.5'), isTrue);
      expect(isPrivateHost('192.168.1.10'), isTrue);
      expect(isPrivateHost('172.16.0.1'), isTrue);
      expect(isPrivateHost('172.31.255.254'), isTrue);

      // 172.15 and 172.32 sit outside the /12 and are ordinary public space.
      expect(isPrivateHost('172.15.0.1'), isFalse);
      expect(isPrivateHost('172.32.0.1'), isFalse);
      expect(isPrivateHost('9.9.9.9'), isFalse);
      expect(isPrivateHost('11.0.0.1'), isFalse);
    });

    test('loopback and link-local', () {
      expect(isPrivateHost('localhost'), isTrue);
      expect(isPrivateHost('127.0.0.1'), isTrue);
      expect(isPrivateHost('169.254.4.4'), isTrue);
      expect(isPrivateHost('[::1]'), isTrue);
      expect(isPrivateHost('fd00::1'), isTrue);
      expect(isPrivateHost('[fe80::1%eth0]'), isTrue);
      expect(isPrivateHost('2606:4700::1111'), isFalse);
    });

    test('the suffixes a home network hands out', () {
      expect(isPrivateHost('pantry.local'), isTrue);
      expect(isPrivateHost('nas.lan'), isTrue);
      expect(isPrivateHost('cloud.home.arpa'), isTrue);
      expect(isPrivateHost('CLOUD.LOCAL'), isTrue);
    });

    test('a name with no dot resolves only against a local suffix', () {
      expect(isPrivateHost('nas'), isTrue);
      expect(isPrivateHost('cloud.example'), isFalse);
    });

    test('an octet-shaped name that is not an address is judged as a name', () {
      // Four labels, but not numbers — a real hostname, and a public one.
      expect(isPrivateHost('10.0.0.example'), isFalse);
      expect(isPrivateHost('999.1.1.1'), isFalse);
    });

    test('a public name pointing somewhere private still reads as public', () {
      // Split-horizon DNS, and the reason a no here decides nothing: this is
      // 192.168.1.10 on the wearer's own network and nothing in the address
      // says so.
      expect(isPrivateHost('pantry.example.com'), isFalse);
    });
  });

  group('serverUrlAfterRedirect', () {
    const api = '/ocs/v2.php/apps/pantry/api/houses/1/items/2';

    test('reads a scheme upgrade off the redirect', () {
      expect(
        serverUrlAfterRedirect(
          'http://cloud.example',
          Uri.parse('http://cloud.example$api'),
          Uri.parse('https://cloud.example$api'),
        ),
        'https://cloud.example',
      );
    });

    test('keeps a subpath the server moved to', () {
      expect(
        serverUrlAfterRedirect(
          'https://example.com',
          Uri.parse('https://example.com$api'),
          Uri.parse('https://www.example.com/nextcloud$api'),
        ),
        'https://www.example.com/nextcloud',
      );
    });

    test('drops a subpath the server moved off', () {
      expect(
        serverUrlAfterRedirect(
          'https://example.com/nextcloud',
          Uri.parse('https://example.com/nextcloud$api'),
          Uri.parse('https://cloud.example.com:8443$api'),
        ),
        'https://cloud.example.com:8443',
      );
    });

    test('names nothing when the path was not carried over', () {
      expect(
        serverUrlAfterRedirect(
          'https://cloud.example',
          Uri.parse('https://cloud.example$api'),
          Uri.parse('https://portal.example/login'),
        ),
        isNull,
      );
    });
  });
}
