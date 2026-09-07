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
}
